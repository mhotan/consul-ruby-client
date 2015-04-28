require 'base64'
require_relative 'base'
require_relative '../model/key_value'

module Consul
  module Client
    class KeyValue < Base

      # Public: Constructor with options hash
      #
      # Optional Parameters:
      #   options[:namespace]   - The KeyValue Store namespace.
      #   options[:data_center] - The consul data center.
      #   options[:api_host]    - The api host to request against.
      #   options[:api_port]    - The api port the api host is listening to.
      #   options[:version]     - The Consul API version to use.
      #   options[:logger]      - The default logging mechanism.
      #
      # Return: This instance
      def initialize(options = nil)
        super(options)
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
        begin
          resp = _get build_url(compose_key(key)), params
        rescue Exception => e
          logger.warn("Unable to get value for #{key} due to: #{e}")
          return nil
        end
        return nil if resp.code == 404
        json = JSON.parse(resp)
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
          logger.debug("Using non-JSON value for key #{key}")
        end
        _put build_url(compose_key(key)), value, {:params => params}
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

      # Public: Returns the name space of this KeyValue Store.  This allows you to
      # identify what root namespace all keys will be placed under.
      #
      # Returns: Namespace String.
      def namespace
        @namespace ||= options[:namespace] || ''
      end

      def build_url(suffix)
        "#{base_versioned_url}/kv/#{suffix}"
      end

      private

      def sanitize(key)
        unless key.nil? or !key.respond_to?(:to_s)
          key = key.to_s
          while !key.empty? and key[0] == '/' do
            key[0] = ''
          end
          while !key.empty? and key[key.length - 1] == '/' do
            key[key.length - 1] = ''
          end
        end
      end

      def compose_key(key)
        ns = namespace.strip
        return "#{key}" if ns.empty?
        "#{ns}/#{key}"
      end

    end
  end
end