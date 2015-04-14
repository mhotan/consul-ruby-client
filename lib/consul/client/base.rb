require 'json'
require 'logger'
require 'rest-client'
require_relative '../util/utils'

module Consul
  module Client

    # Public API Base.
    module Base

      # Public: Creates an API Endpoint
      #
      # data_center - The data center to utilize, defaults to bootstrap 'dc1' datat center
      # api_host    - The host the Consul Agent is running on. Default: 127.0.0.1
      # api_port    - The port the Consul Agent is listening on. Default: 8500
      # version     - The version of the api to use.
      # logger      - Logging mechanism.  Must conform to Ruby Logger interface
      #
      def initialize(data_center = 'dc1', api_host = '127.0.0.1', api_port = '8500', version = 'v1', logger = Logger.new(STDOUT))
        @dc = data_center
        @host = api_host
        @port = api_port
        @logger = logger
        @version = version
      end

      # Public: Test if this Consul Client is reachable.
      def is_reachable
        get(base_url, nil, false) == 'Consul Agent'
      end

      protected

      # Protected: Generic get request.  Wraps error handling and url validation.
      #
      # url       - url endpoint to hit.
      # params    - Hash of key to value parameters
      # json_only - Flag that annotates we should only be expecting json back.  Default true, most consul endpoints return JSON.
      #
      # Returns:
      # Throws:
      #     ArgumentError: the url is not valid.
      #     IOError: Unable to reach Consul Agent.
      def get(url, params = nil, json_only = true)
        # Validation
        validate_url(url)

        opts = {}
        opts[:params] = params unless params.nil?
        opts[:accept] = :json if json_only
        begin
          return RestClient.get url, opts
        rescue Exception => e
          # Unable to communicate with consul agent.
          logger.warn(e.message)
          raise IOError.new "Unable to complete get request: #{e}"
        end
      end

      # Protected: Generic put request.  Wraps error and translates Rest response to success or failure.
      #
      # url    - The url endpoint for the put request.
      # value  - The value to put at the url endpoint.
      #
      # Returns: true on success or false on failure and the body of the return message.
      # Throws:
      #     ArgumentError: the url is not valid.
      #     IOError: Unable to reach Consul Agent.
      def put(url, value, params = nil)
        # Validation
        validate_url(url)

        p = {}
        p[:params] = params unless params.nil?
        begin
          if Consul::Utils.valid_json?(value)
            resp = RestClient.put(url, value, :content_type => :json) {|response, req, res| response }
          else
            resp = RestClient.put(url, value) {|response, req, res| response }
          end
          logger.warn("Unable to send #{value} to endpoint #{url} returned code: #{resp.code}") unless resp.code == 200
          return (resp.code == 200 or resp.code == 201), resp.body
        rescue Exception => e
          logger.error('RestClient.put Error: Unable to reach consul agent')
          raise IOError.new "Unable to complete put request: #{e}"
        end
      end

      def data_center
        @data_center ||= 'dc1'
      end

      def host
        @host ||= '127.0.0.1'
      end

      def port
        @port ||= '8500'
      end

      def version
        @version ||= 'v1'
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def https
        @https = false
      end

      def base_versioned_url
        "#{base_url}/#{version}"
      end

      private

      def base_url
        "#{(https ? 'https': 'http')}://#{host}:#{port}"
      end

      # Private: Validates the url
      def validate_url(url)
        raise ArgumentError.new 'URL cannot be blank' if url.to_s == ''
      end

    end
  end
end
