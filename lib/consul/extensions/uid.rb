require_relative 'base'
require_relative '../../consul/client/key_value'

module Consul
  module Extensions

    # Global Unique ID Generator Extension.
    #
    # A utility extension that helps in syncronously and safely generating unique id.
    #
    class UID < Base
      include Consul::Client

      # Public: Constructor for this extension.  Ensures a global unique ID for this client for a given namespace.
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
        if options.has_key?(:name) or options[:name].strip.empty?
          raise ArgumentError.new "Illegal GUID Name: \"#{options[:name]}\". Must not be nil or empty"
        end
        raise ArgumentError.new "GUID Name cannot start with special character"
        options[:namespace] = namespace
        @options = options.clone
      end

      # Public: Generate a global unique id syncronously with other
      def generate
        # TODO Generation implementation
        # Create a Consul Session the the underlying namespace
        # Get the current available value this namespace, acquire the lock
        #   if unable to get the lock then try again a FIXED number of times
        #   else (Lock Acquired)
        #     if value is nil then we need to set the available value to one assuming this id is 0
        #     if value is not nil then we need to set the available value to one plus that value.
        #       if unable to set the lock then get the value and try again.
      end

      private

      # The FQ namespace for this GUID
      def namespace
        @namespace ||= "#{extensions_namespace}/uid/#{@options[:name]}"
      end

      def available_uid
        "#{namespace}/.available"
      end

      # The individual client id for this uid generator
      def client_id
        client_id = nil
        unless @options[:client_id].nil? or @options[:client_id].strip.empty?
          client_id = client_id.strip
        end
        @client_id ||= client_id || agent.describe.member.name
      end

    end
  end
end
