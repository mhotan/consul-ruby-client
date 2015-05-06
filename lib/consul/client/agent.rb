require_relative 'base'
require_relative '../model/agent'
require_relative '../model/service'
require_relative '../model/health_check'

# Consul Agent Client.
# Represents Ruby endpoint as described here: https://www.consul.io/docs/agent/http/agent.html
module Consul
  module Client
    class Agent < Base

      # Public: Describes the agent.  It is actually the same method as /v1/agent/self
      #
      # Example:
      #          a = Agent.new
      #          a.describe =>
      #             <Consul::Model::Agent config=#<Consul::Model::Config bootstrap=true, server=true,
      #               datacenter="dc1", datadir="/path/to/data", dns_recursor="", dns_recursors=[],
      #               domain="consul.", log_level="INFO", node_name="MyComputer.local", client_addr="127.0.0.1",
      #               bind_addr="0.0.0.0", advertise_addr="172.19.12.106", ports={"DNS"=>8600, "HTTP"=>8500, "HTTPS"=>-1,
      #               "RPC"=>8400, "SerfLan"=>8301, "SerfWan"=>8302, "Server"=>8300}, leave_on_term=false,
      #               skip_leave_on_int=false, stat_site_addr="", protocol=2, enable_debug=false, verify_incoming=false,
      #               verify_outgoing=false, ca_file="", cert_file="", key_file="", start_join=[], ui_dir="", pid_file="",
      #               enable_syslog=false, rejoin_after_leave=false>, member=#<Consul::Model::Member name="MyComputer.local",
      #               addr="172.19.12.106", port=8301, tags={"bootstrap"=>"1", "build"=>"0.5.0:0c7ca91c", "dc"=>"dc1", "port"=>"8300",
      #               "role"=>"consul", "vsn"=>"2", "vsn_max"=>"2", "vsn_min"=>"1"}, status=1, protocol_min=1, protocol_max=2,
      #               protocol_cur=2, delegate_min=2, delegate_max=4, delegate_cur=4>>
      #           a.describe.config.node_name =>
      #             "MyComputer.local"
      #           a.describe.member.name =>
      #             "MyComputer.local"
      #
      # Return: Consul::Model::Agent instance that represents this agent.
      def describe
        begin
          resp = _get build_agent_url('self')
        rescue
          logger.warn('Unable to request all the services on this through the HTTP API')
          return nil
        end
        Consul::Model::Agent.new.extend(Consul::Model::Agent::Representer).from_json(resp)
      end

      # Public: Returns all the services registered with this Agent.
      #
      # Returns: An array of all the ConsulService(s) registered on this agent.
      def services
        begin
          resp = _get build_agent_url('services')
        rescue
          logger.warn('Unable to request all the services on this through the HTTP API')
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
          resp = _get build_agent_url('checks')
        rescue
          logger.warn('Unable to request all the checks on this through the HTTP API')
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

      # Public: Returns a Health Check for a specific service.
      #
      # service_id - The ID of the service.
      def service_check(service_id)
        check("service:#{service_id}")
      end

      # Public: Registers either a service or a Health check with configured consul agent.
      #
      # entity - Consul::Model::Service or Consul::Model::HealthCheck instance.
      #
      # Example
      #   agent = Consul::Client::Agent.new('dc1')
      #   # Register a service
      #   agent.register(Consul::Client::Agent::Service.for_name('cat'))
      #   # Register a HealthCheck
      #   agent.register(Consul::Client::HealthCheck.ttl('my_check_name', '15m'))
      #   # Register a service with a Consul Health Check
      #   agent.register(Consul::Client::Agent::Service.for_name('cat', Consul::Client::Agent::Service.ttl_health_check('15m')))
      #
      # Returns true upon success, false upon failure
      def register(entity)
        raise TypeError unless entity.kind_of? Consul::Model::HealthCheck or entity.kind_of? Consul::Model::Service
        case entity
          when Consul::Model::HealthCheck
            return register_with_backoff(build_check_url('register'), entity.extend(Consul::Model::HealthCheck::Representer), 0, 3)
          else
            entity = entity.extend(Consul::Model::Service::Representer)
            success, body = _put build_service_url('register'), entity.to_json
            if success
              logger.info("Successfully registered service #{entity.name}.")
              c = check("service:#{entity.name}") unless entity.check.nil?
              unless c.nil?
                # Pass the first health check
                logger.info("Updating status for health check #{c.check_id} to \"pass\".")
                _get build_check_status_url(c.check_id, 'pass')
              end
            else
              logger.warn("Unable to register #{entity}. Reason: #{body}")
            end
            return success
        end
      end

      # Public: deregisters an existing ConsulHealthCheck or ConsulService
      #
      # entity - Consul::Model::HealthCheck or Consul::Model::ConsulService to unregister from this
      #
      # Returns - the HTTP Response
      def deregister(entity)
        unless entity.nil?
          raise TypeError unless entity.kind_of? Consul::Model::HealthCheck or entity.kind_of? Consul::Model::Service
          case entity
            when Consul::Model::HealthCheck
              url = build_check_url('deregister')
            else
              url = build_service_url('deregister')
          end
          _get "#{url}/#{entity.id}"
        end
      end

      # Public: Pass a health check.
      #
      # check - Consul::Model::HealthCheck to pass.  Cannot be nil or wrong type
      #
      def pass(check)
        update_check_status(check, 'pass')
      end

      # Public: Warn a health check
      #
      # check - Consul::Model::HealthCheck to pass.  Cannot be nil or wrong type
      #
      def warn(check)
        update_check_status(check, 'warn')
      end

      # Public: Fails a health check
      #
      # check - Consul::Model::HealthCheck to pass.  Cannot be nil or wrong type
      #
      def fail(check)
        update_check_status(check, 'fail')
      end

      # Public: Enter maintenance mode.
      #
      # enable  - Flag to indicate to enable maintanence mode or not
      # service - Set maintanence for a particular service is set.
      # reason  - Optional reason.
      def maintenance(enable, service = nil, reason = nil)
        if service.nil?
          url = build_agent_url('maintenance')
        else
          if service.instance_of?(Consul::Model::Service)
            service = service.id
          end
          raise ArgumentError.new "Unable to create request for #{service}" unless service.respond_to?(:to_str)
          url = build_service_url("maintenance/#{service}")
        end
        params = {:enable => enable}
        params[:reason] = reason unless reason.nil?
        _get url, params
      end

      module HealthCheck

        # Public: TTL Check
        #
        # name  - The name of the check, Cannot be nil
        # ttl   - Time to live time window. IE "15s", Cannot be nil
        # id    - ID to associate with this check if 'name' is not desired.
        # notes - Message to place as notes for this check
        #
        # Returns: Consul::Model::HealthCheck instance
        def self.ttl(name, ttl, id = name, notes = nil)
          validate_arg name
          validate_arg ttl
          c = Consul::Model::HealthCheck.new(name: name, ttl: ttl)
          c.id = id unless id.nil?
          c.notes = notes unless notes.nil?
          c
        end

        # Public: Script Check
        #
        # name      - The name of the check, Cannot be nil
        # script    - The script to run locally
        # interval  - The time interval to conduct the check. IE: '10s'
        # id        - ID to associate with this check if 'name' is not desired.
        # notes     - Message to place as notes for this check.
        #
        # Returns: Consul::Model::HealthCheck instance
        def self.script(name, script, interval, id = name, notes = nil)
          validate_arg name
          validate_arg script
          validate_arg interval
          c = Consul::Model::HealthCheck.new(name: name, script: script, interval: interval)
          c.id = id unless id.nil?
          c.notes = notes unless notes.nil?
          c
        end

        # Public: HTTP Check
        #
        # name      - The name of the check, Cannot be nil
        # http      - The HTTP endpoint to hit with periodic GET.
        # interval  - The time interval to conduct the check. IE: '10s'
        # id        - ID to associate with this check if 'name' is not desired.
        # notes     - Message to place as notes for this check
        #
        # Returns: Consul::Model::HealthCheck instance
        def self.http(name, http, interval, id = name, notes = nil)
          validate_arg name
          validate_arg http
          validate_arg interval
          c = Consul::Model::HealthCheck.new(name: name, http: http, interval: interval)
          c.id = id unless id.nil?
          c.notes = notes unless notes.nil?
          c
        end

        private

        def self.validate_arg(arg)
          raise ArgumentError.new "Illegal Argument: #{arg}" if arg.nil? or arg.empty?
        end

      end

      # Container Module for simpler way to create a service.
      module Service

        # Public: Creates a service using a specific name
        #
        # name  -  Name of the service to create
        # check - The Consul::Model::HealthCheck instance to associate with this Session
        #
        # Returns: Consul::Model::Service instance
        def self.for_name(name, check = nil)
          raise ArgumentError.new "Illegal name: \"#{name}\" for service." if name.nil?
          unless check.nil? or check.is_a?(Consul::Model::HealthCheck)
            raise TypeError.new "Illegal Check type: #{check}.  Expecting Consul::Model::HealthCheck"
          end
          if check.nil?
            Consul::Model::Service.new(name: name)
          else # There is a health check to register
            Consul::Model::Service.new(name: name, check: check)
          end
        end

        # Returns: Consul::Model::HealthCheck instance that represents a script
        def self.script_health_check(script, interval)
          Consul::Model::HealthCheck.new(script: script, interval: interval)
        end

        # Returns: Consul::Model::HealthCheck instance that represents a http health check.
        def self.http_health_check(http, interval)
          Consul::Model::HealthCheck.new(http: http, interval: interval)
        end

        def self.ttl_health_check(ttl)
          Consul::Model::HealthCheck.new(ttl: ttl)
        end
      end

      private

      # Private: Updates the check with the argument status.
      def update_check_status(check, status)
        unless check.instance_of?(Consul::Model::HealthCheck) and check.respond_to?(:to_str)
          check = check(check.to_str)
        end
        return false if check.nil?
        raise ArgumentError.new "Illegal Status #{status}" unless status == 'pass' or status == 'warn' or status == 'fail'
        resp = _get build_check_url("#{status}/#{check.check_id}")
        resp.code == 200
      end

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
          success, _ = _put(url, entity.to_json)
          unless success # Unless we successfully registered.
            if threshold == iteration
              logger.error("Unable to complete registration after #{threshold + 1} attempts")
              return false
            else
              # Attempt to register again using the exponential backoff.
              logger.warn("Unable to complete registration after #{iteration + 1} attempts, Retrying up to #{threshold+1} attempts")
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
