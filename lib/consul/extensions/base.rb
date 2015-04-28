
module Consul
  module Extensions
    class Base

      # Public: Constructor for this extension.  Ensures a global unique ID for this client for a given namespace.
      #
      #   options               - (Optional) Hash of Consul Client and extension options.
      #   options[:data_center] - (Optional) The Consul data center. Default: 'dc1'.
      #   options[:api_host]    - (Optional) The Consul api host to request against.  Default: '127.0.0.1'.
      #   options[:api_port]    - (Optional) The Consul api port the api host is listening to. Default: '8500'.
      #   options[:version]     - (Optional) The Consul API version to use. Default: 'v1'.
      #   options[:logger]      - (Optional) The default logging mechanism. Default: Logger.new(STDOUT).
      #
      # Extension instance capable of generating GUID.
      def initialize(options)
        options = {} if options.nil?
        @options = options.clone
      end

      protected

      # Semantically private namespace for consul-ruby-client extensions.
      def extensions_namespace
        '.extensions'
      end

      # The Consul Agent Client to use
      def agent
        @agent = Agent.new(options)
      end

      # The Key Value Store to use.
      def key_value_store
        @kvs = KeyValue.new(options)
      end

      # TODO Add other clients here.

      private

      def options
      @options
      end


    end
  end
end
