require 'base64'
require_relative 'base'
require_relative '../model/key_value'

module Consul
  module Client
    class KeyValue
      include Consul::Client::Base

      # Public: Creates an API Endpoint
      #
      # data_center - The data center to utilize, defaults to bootstrap 'dc1' datat center
      # api_host    - The host the Consul Agent is running on. Default: 127.0.0.1
      # api_port    - The port the Consul Agent is listening on. Default: 8500
      # version     - The version of the api to use.
      # logger      - Logging mechanism.  Must conform to Ruby Logger interface
      #
      def initialize(name_space = '', data_center = 'dc1', api_host = '127.0.0.1', api_port = '8500', version = 'v1', logger = Logger.new(STDOUT))
        name_space = sanitize(name_space)
        name_space = "#{name_space}/" unless name_space.nil? or name_space.empty?
        @namespace = sanitize(name_space)
        @dc = data_center
        @host = api_host
        @port = api_port
        @logger = logger
        @version = version
      end

      def name_space
        @namespace ||= ''
      end

      # Public: Gets the value associated with a given key.
      #
      # Reference: https://www.consul.io/docs/agent/http/kv.html
      #
      # key       - Key to get value for, if recurse = true the key is treated by a prefix
      # recurse   - Flag to signify treating the key as a prefix
      # index     - Can be used to establish blocking queries by setting
      # only_keys - Flag to return only keys
      # separator - list only up to a given separator
      #
      # Returns: An array of Consul::Model::KeyValue objects, if only
      def get(key,
              recurse = false,
              index = false,
              only_keys = false,
              separator = nil)
        key = sanitize(key)
        params = {}
        params[:recurse] = nil if recurse
        params[:index] = nil if index
        params[:keys] = nil if only_keys
        params[:separator] = separator unless separator.nil?
        # begin
        #   resp = RestClient.get key_url(key), {:params => params}
        # rescue
        #   # TODO need to pass more information back to the client.
        #   logger.warn("Unable to get value for #{key}")
        #   nil
        # end
        begin
          resp = _get key_url(key), params
        rescue Exception => e
          logger.warn("Unable to get value for #{key} due to: #{e}")
          return nil
        end
        return nil if resp.code == 404
        json = JSON.parse(_get key_url(key), params)
        return json if only_keys
        json.map { |kv|
          kv = Consul::Model::KeyValue.new.extend(Consul::Model::KeyValue::Representer).from_hash(kv)
          kv.value = Base64.decode64(kv.value)
          kv
        }
      end

      # Public: Put the Key Value pair in consul.
      #
      # Low level put key value implementation.
      #
      # Reference: https://www.consul.io/docs/agent/http/kv.html
      #
      # key     - Key
      # value   - Value to assign for Key
      # flags   - Client specified value [0, 2e64-1]
      # cas     - Check and Set operation
      # acquire - Session id to acquire the lock with a valid session.
      # release - Session id to release the lock with a valid session.
      #
      # Returns: True on success, False on failure
      # Throws: IOError: Unable to contact Consul Agent.
      def put(key,
              value,
              flags = nil,
              cas = nil,
              acquire_session = nil,
              release_session = nil)
        key = sanitize(key)
        params = {}
        params[:flags] = flags unless flags.nil?
        params[:cas] = cas unless cas.nil?
        params[:acquire] = acquire_session unless acquire_session.nil?
        params[:release_session] = release_session unless release_session.nil?
        begin
          value = JSON.generate(value)
        rescue JSON::GeneratorError
          @logger.debug("Using non-JSON value for key #{key}")
        end
        _put build_url(key), value, {:params => params}
      end

      # Public: Delete the Key Value pair in consul.
      #
      # key     - Key
      # recurse - Delete all keys as the 'key' is a prefix for
      # cas     - Check and Set
      def delete(key, recurse = false, cas = nil)
        key = sanitize(key)
        params = {}
        params[:recurse] = nil if recurse
        params[:cas] = cas unless cas.nil?
        RestClient.delete build_url(key), {:params => params}
      end

      def build_url(suffix)
        "#{base_versioned_url}/kv/#{suffix}"
      end

      private

      def sanitize(key)
        key.gsub(/^\//,'').gsub(/\/$/,'')
      end

      def key_url(key)
        build_url("#{name_space}#{key}")
      end

    end
  end
end