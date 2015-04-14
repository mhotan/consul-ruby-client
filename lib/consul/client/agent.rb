require_relative 'base'
require_relative '../model/service'
require_relative '../model/health_check'

# Consul Agent Client.
# Represents Ruby endpoint as described here: https://www.consul.io/docs/agent/http/agent.html
module Consul
  module Client
    class Agent
      include Consul::Client::Base

      # Public: Returns all the services registered with this Agent.
      #
      # Returns: An array of all the ConsulService(s) registered on this agent.
      def services
        begin
          resp = get build_agent_url('services')
        rescue
          @logger.warn('Unable to request all the services on this through the HTTP API')
          return nil
        end
        # Consul returns id => ConsulServiceObjects.
        s_hash = JSON.parse(resp)
        s_hash.keys.map { |n| Consul::Model::Service.new.extend(Consul::Model::Service::Representer).from_hash(s_hash[n]) }
      end

      # Public: Returns the service that has the associated name.
      #
      # Returns: ConsulService if exists, nil if no service by this name exists.
      def service(id)
        ss = services
        ss.keep_if {|s| s.id == id}.first unless ss.nil?
      end

      def checks
        begin
          resp = get build_agent_url('checks')
        rescue
          @logger.warn('Unable to request all the checks on this through the HTTP API')
          return nil
        end
        # Consul returns id => ConsulServiceObjects.
        s_hash = JSON.parse(resp)
        s_hash.keys.map { |n| Consul::Model::HealthCheck.new.extend(Consul::Model::HealthCheck::Representer).from_hash(s_hash[n]) }
      end

      # Public: Returns a check by a given id.
      # Returns: nil if no such check exists, or the check instance with the correct id
      def check(id)
        c = checks
        c.keep_if {|c| c.check_id == id}.first unless c.nil?
      end

      # Public: Registers either a service or a Health check with configured consul agent.
      #
      # entity - CO or ConsulService instance
      # opts - Rest options.
      #
      # Example
      #   agent = Consul::Client::Agent.new('dc1')
      #   # Register a service
      #   agent.register()
      #   # Register a HealthCheck
      #   agent.register(ConsulHealthCheck.new(:id => 'my_health_service', ttl: '15s'))
      #   # Register a service with a Consul Health Check
      #   agent.register(ConsulService.new(:id => 'hello_world_service', check: ConsulHealthCheck.new(ttl: '15s')))
      #
      # Returns true upon success, false upon failure
      def register(entity)
        raise TypeError unless entity.kind_of? Consul::Model::HealthCheck or entity.kind_of? Consul::Model::Service
        case entity
          when Consul::Model::HealthCheck
            return register_with_backoff(build_check_url('register'), entity.extend(Consul::Model::HealthCheck::Representer), 0, 3)
          else
            entity = entity.extend(Consul::Model::Service::Representer)
            success = register_with_backoff(build_service_url('register'), entity, 0, 3)
            if success
              @logger.info("Successfully registered service #{entity.name}.")
              unless entity.check.nil?
                # Pass the first health check
                c = check("service:#{entity.name}")
                @logger.info("Updating status for health check #{c.check_id} to \"pass\".")
                get build_check_status_url(c.check_id, 'pass')
              end
            end
            return success
        end
      end

      # Public: deregisters an existing ConsulHealthCheck or ConsulService
      #
      # entity - ConsulHealthCheck or ConsulService to unregister from this
      #
      # Returns - the HTTP Response
      def deregister(entity)
        raise TypeError unless entity.kind_of? Consul::Model::HealthCheck or entity.kind_of? Consul::Model::Service
        case entity
          when Consul::Model::HealthCheck
            url = build_check_url('deregister')
          else
            url = build_service_url('deregister')
        end
        get "#{url}/#{entity.id}"
      end

      # # Register a service on this consul agent.
      # #
      # # The service will be associated to the IP address of this machine.
      # # The ttl argument is the time that the service has to live until it needs to send another heartbeat signal.
      # def register_service(service_name,
      #                      ttl,
      #                      port = nil)
      #   unless service_name.nil? or ttl.nil?
      #     url = build_service_url("register")
      #     begin
      #       service_hash = { :Name => service_name,
      #                        :Port => port,
      #                        :Check => { :TTL => ttl }
      #       }.reject{ |k,v| v.nil? }
      #       service_name = JSON.generate(service_hash)
      #     rescue JSON::GeneratorError
      #       @logger.error("Using non-JSON value for key #{service_hash}.  Skipped registration of #{service_name}")
      #     end
      #   end
      #   @logger.debug("Registering service: '#{service_name}' at location: '#{url}'")
      #   register_service_with_expbackoff(url, service_name, 0, 3)
      # end
      #
      # # Deregisters the service if the service exists on this agent.
      # def deregister_service(service_name)
      #   unless service_name.nil?
      #     url = "#{build_service_url("deregister")}/#{service_name}"
      #     @logger.debug("Deregistering service: '#{service_name}' at '#{url}'")
      #     RestClient.get url
      #   end
      # end

      private

      # Private: Register a consul entity with the existing agent but attempts and exponentially increasing interval if
      # fails.
      #
      # url - The url to make the register request through.
      # entity - JSON representation of the entity
      # iteration - The current attempt iteration
      # threshold - Number of attempts to try
      #
      def register_with_backoff(url, entity, iteration, threshold)
        # Checking a greater iteration just to be on the safe side.
        unless iteration > threshold or threshold <= 0 or iteration < 0
          sleep((1.0/2.0*(2.0**iteration - 1.0)).ceil) if iteration > 0
          success, _ = put(url, entity.to_json)
          unless success # Unless we successfully registered.
            if threshold == iteration
              @logger.error("Unable to complete registration after #{threshold + 1} attempts")
            else
              # Attempt to register again using the exponential backoff.
              @logger.warn("Unable to complete registration after #{iteration + 1} attempts, Retrying up to #{threshold+1} attempts")
              register_with_backoff(url, entity, iteration + 1, threshold)
            end
          end
          return true
        end
        false
      end

      def build_service_url(suffix)
        build_agent_url("service/#{suffix}")
      end

      def build_check_url(suffix)
        build_agent_url("check/#{suffix}")
      end

      # status : "pass", "warn", or "fail"
      def build_check_status_url(check_id, status)
        build_check_url("#{status}/#{check_id}")
      end

      # Returns host:port/v1/agent/suffix
      def build_agent_url(suffix)
        "#{base_versioned_url}/agent/#{suffix}"
      end

    end
  end
end