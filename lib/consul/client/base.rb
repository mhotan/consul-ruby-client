require 'json'
require 'logger'
require 'rest-client'
require_relative '../util/utils'

module Consul
  module Client

    # Public API Base.
    class Base

      # Public: Constructor with options hash
      #
      # Optional Parameters:
      #   options[:data_center] - The consul data center. Default: 'dc1'.
      #   options[:api_host]    - The api host to request against.  Default: '127.0.0.1'.
      #   options[:api_port]    - The api port the api host is listening to. Default: '8500'.
      #   options[:version]     - The Consul API version to use. Default: 'v1'.
      #   options[:logger]      - The default logging mechanism. Default: Logger.new(STDOUT).
      #
      # Return: This instance
      def initialize(options = nil)
        options = {} if options.nil?
        raise TypeError, 'Options must be nil or a Hash' unless options.is_a?(Hash)
        @options = options.clone
      end

      # Public: Test if this Consul Client is reachable.
      def is_reachable
        _get(base_url, nil, false) == 'Consul Agent'
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
      def _get(url, params = nil, json_only = true)
        # Validation
        validate_url(url)

        opts = {}
        opts[:params] = params unless params.nil?
        opts[:accept] = :json if json_only

        begin
          resp = makeRequestWithProxySetting {
            RestClient.get url, opts
          }

          success = (resp.code == 200 or resp.code == 201)
          if success
            logger.debug("Successful GET at endpoint #{url}")
          else
            logger.warn("Unable to GET from endpoint #{url} returned code: #{resp.code}")
          end
          return resp
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
      def _put(url, value, params = nil)
        # Validation
        validate_url(url)

        # If possible, Convert value to json
        unless Consul::Utils.valid_json?(value)
          value = value.to_json if value.respond_to?(:to_json)
        end

        opts = {}
        opts[:params] = params unless params.nil?
        begin
          opts[:content_type] = :json if Consul::Utils.valid_json?(value)

          resp = makeRequestWithProxySetting {
            RestClient.put(url, value, opts) {|response, req, res| response }
          }

          success = (resp.code == 200 or resp.code == 201)
          if success
            logger.debug("Successful PUT #{value} at endpoint #{url}")
          else
            logger.warn("Unable to PUT #{value} at endpoint #{url} returned code: #{resp.code}")
          end
          return success, resp.body
        rescue Exception => e
          logger.error('RestClient.put Error: Unable to reach consul agent')
          raise IOError.new "Unable to complete put request: #{e}"
        end
      end

      def makeRequestWithProxySetting
        oldProxySetting = RestClient.proxy
        RestClient.proxy = @options[:proxy]

        response = yield

        RestClient.proxy = oldProxySetting

        response
      end

      def options
        @options ||= {}
      end

      def data_center
        @data_center ||= options[:data_center] || 'dc1'
      end

      def host
        @host ||= options[:api_host] || '127.0.0.1'
      end

      def port
        @port ||= options[:api_port] || '8500'
      end

      def version
        @version ||= options[:version] || 'v1'
      end

      def logger
        @logger ||= options[:logger] || Logger.new(STDOUT)
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
