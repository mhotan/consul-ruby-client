require_relative 'base'
require_relative '../../consul/client/key_value'
require_relative '../model/member'

module Consul
  module Extensions

    # Global Unique ID Generator Extension.
    #
    # A utility extension that helps in syncronously and safely generating unique id.
    #
    class UID < Base
      include Consul::Client

      MAX_ATTEMPTS = 10

      # Public: Constructor for this extension.  Ensures a global unique ID for this client for a given namespace.
      #
      # Under the covers UID generator associates the Consul agent to the determine its individuality away from other clients.
      # the opts[:client_id] parameter is used to expose an external parameter to allow clients to determin uniqueness.
      #
      # For Example:
      #   catOpts = {:name => 'animal', :client_id => 'cat'}
      #   otherCatOpts = {:name => 'animal', :client_id => 'cat'}
      #   dogOpts = {:name => 'animal', :client_id => 'dog'}
      #
      # UID.new(catOpts).get will return the same UID as UID.new(otherCatOpts).get
      # UID.new(catOpts).get  will return different UIDs from UID.new(dogOpts).get
      #
      #   options               - (Required) Hash of Consul Client and extension options.
      #   options[:name]        - (Required) The name or name space of the GUID to generate.  This extension will
      #                           generate a GUID with respect to other clients is this name space.
      #   options[:client_id]   - (Optional) External Client ID.  This is an additional semantic parameter external to consul.
      #                           This provides the capability to unique identify your external client.
      #                           Default: Consul Agent name.  Cannot begin with "."
      #   options[:data_center] - (Optional) The Consul data center. Default: 'dc1'.
      #   options[:api_host]    - (Optional) The Consul api host to request against.  Default: '127.0.0.1'.
      #   options[:api_port]    - (Optional) The Consul api port the api host is listening to. Default: '8500'.
      #   options[:version]     - (Optional) The Consul API version to use. Default: 'v1'.
      #   options[:logger]      - (Optional) The default logging mechanism. Default: Logger.new(STDOUT).
      #
      # Extension instance capable of generating GUID.
      def initialize(options)
        raise TypeError.new "Options must not be a Hash that contains \":name\"" unless options.is_a?(Hash)
        if options[:name].nil? or options[:name].strip.empty?
          raise ArgumentError.new "Illegal GUID Name: \"#{options[:name]}\". Must not be nil or empty"
        end
        raise ArgumentError.new "GUID Name cannot start with special character" unless /^[^0-9A-Za-z].*/.match(options[:name]).nil?
        @name = options[:name]
        options[:namespace] = namespace
        @options = options.clone
      end

      # Public: Generate a global unique id synchronously with other
      def get
        # TODO Generation implementation
        # Create a Consul Session the the underlying namespace
        cur_session = session.create(Session.for_name(namespace))
        raise 'Unable to create session to generate UID.' if cur_session.nil?

        # Check if there is already an UID associated with this client_id.
        existing_uid = key_value_store.get(client_uid_path)
        unless existing_uid.nil? or (existing_uid.respond_to?(:empty?) and existing_uid.empty?)
          return existing_uid[0].value.to_i
        end

        # No existing UID so let provision one for this node.
        for i in 1..MAX_ATTEMPTS
          session.renew cur_session # Renew the current session so we can obtain a lock

          # Get the current available uid with
          auid = key_value_store.get(available_uid_path, {:index => nil})
          if auid.nil? # Key does not exists. Which also means its the first ever UID.
            logger.debug("First ever UID for #{namespace}")
            auid = 0
          else
            auid = auid[0].value.to_i
            logger.debug("Found available UID for #{namespace} value: #{auid}")
          end
          # Acquire the lock
          member = agent.describe.member.to_json
          acquire_lock_success, body = key_value_store.put(available_lock_path,
                                                           member,
                                                           {:acquire => cur_session.id})
          unless acquire_lock_success
            logger.warn("Attempt: #{i} Unable to acquire lock for #{namespace} reason: #{body}")
            next
          end

          # Update the available uid with the next value
          available_uid_update_success, body = key_value_store.put(available_uid_path, auid + 1)
          unless available_uid_update_success
            logger.warn("Attempt: #{i} Unable to update available uid for #{namespace} reason: #{body}")
            next
          end

          # Release the lock
          release_lock_success, body = key_value_store.put(available_lock_path,
                                                           member,
                                                           {:release => cur_session.id})
          logger.warn("Unable to release lock for #{namespace} reason: #{body}.  Resorting to Timeout.") unless release_lock_success

          # Update the Key Value store for this client id so we don't provision another one.
          client_id_update_success, body = key_value_store.put(client_uid_path, auid)
          unless client_id_update_success
            logger.warn("Attempt: #{i} Unable to update id for client #{client_id} with value #{auid} due to #{body}")
            next
          end

          # After successfully and synchronously updating available universal id and this client id continue
          return auid
        end
        logger.error("Unable to generate key after #{MAX_ATTEMPTS} attempts")
        nil
      end

      # Path to getting the next available UID.
      def available_uid_path
        '.available.uid'
      end

      def available_lock_path
        '.available.lock'
      end

      # Path to this specific Client UID.
      def client_uid_path
        client_id
      end

      # The individual client id for this uid generator
      def client_id
        c_id = nil
        unless @options[:client_id].nil? or @options[:client_id].strip.empty?
          c_id = @options[:client_id].strip
        end
        @client_id ||= c_id || agent.describe.member.name
      end

      private

      # The FQ namespace for this GUID
      def namespace
        @namespace ||= "#{extensions_namespace}/uid/#{@name}"
      end

    end
  end
end
