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
      # Params:
      # key                 - Key to get value for
      # params              - Parameter hash for Consul
      # params[:recurse]    - existence of any value with tell consul to remove all keys
      #                       with the same prefix
      # params[:index]      - Existence of :index, indicates to use a blocking call
      # params[:keys]       - Existence of :keys, indicates to only return keys
      # params[:separator]  - List only up to a given separator
      #
      # Returns: An array of Consul::Model::KeyValue objects, if only
      def get(key, params = {})
        key = sanitize(key)
        params = {} if params.nil?
        params[:recurse] = nil if params.has_key?(:recurse)
        params[:index] = nil if params.has_key?(:index)
        params[:keys] = nil if params.has_key?(:keys)
        begin
          resp = _get build_url(compose_key(key)), params
        rescue Exception => e
          logger.warn("Unable to get value for #{key} due to: #{e}")
          return nil
        end
        return nil if resp.code == 404
        json = JSON.parse(resp)
        return json if params.has_key?(:keys)
        json.map { |kv|
          kv = Consul::Model::KeyValue.new.extend(Consul::Model::KeyValue::Representer).from_hash(kv)
          kv.value = Base64.decode64(kv.value) unless kv.value.nil?
          kv
        }
      end

      # Public: Put the Key Value pair in consul.
      #
      # Low level put key value implementation.
      #
      # Reference: https://www.consul.io/docs/agent/http/kv.html
      #
      # key               - Key
      # value             - Value to assign for Key
      # params            - Consul Parameter Hash
      # params[:flags]    - Unsigned value between 0 and 2^(64-1). General purpose parameter.
      # params[:cas]      - Modify index for Check and set operation.
      # params[:acquire]  - session id to use to lock.
      # params[:release]  - session id to use to unlock.
      #
      # Returns: True on success, False on failure
      # Throws: IOError: Unable to contact Consul Agent.
      def put(key, value, params = {})
        key = sanitize(key)
        params = {} if params.nil?
        begin
          value = JSON.generate(value)
        rescue JSON::GeneratorError
          logger.debug("Using non-JSON value: #{value} for key #{key}")
        end
        _put build_url(compose_key(key)), value, params
      end

      # Public: Delete the Key Value pair in consul.
      #
      # key               - Key
      # params            - Parameter Hash
      # params[:recurse]  - Existence of key notifies that all sub keys will be deleted
      # params[:cas]      - Modify index for Check and set operation.
      #
      def delete(key, params = {})
        key = sanitize(key)
        params = {}
        params[:recurse] = nil if params.has_key?(:recurse)
        RestClient.delete build_url(compose_key(key)), {:params => params}
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
        key
      end

      def compose_key(key)
        ns = sanitize(namespace.strip)
        return "#{key}" if ns.empty?
        "#{ns}/#{key}"
      end

    end
  end
end