require 'json'
require_relative 'base'

module Consul
  module Client
    class Status < Base

      # Public: This endpoint is used to get the Raft leader for the
      # datacenter in which the agent is running
      #
      # Reference: https://www.consul.io/docs/agent/http/status.html
      #
      # Returns: Address, host:port.
      def leader
        resp = RestClient.get leader_url
        return resp.body.slice(1, resp.body.length-2) if resp.code == 200
        logger.warn("Unable to get leader. Resp code: #{resp.code} Resp message: #{resp.body}")
        nil
      end

      # Public: This endpoint retrieves the Raft peers for the
      # datacenter in which the the agent is running
      #
      # Reference: https://www.consul.io/docs/agent/http/status.html
      #
      # Returns: List of addresses.
      def peers
        resp = RestClient.get peers_url
        return JSON.parse(resp.body) if resp.code == 200
        logger.warn("Unable to get peers. Resp code: #{resp.code} Resp message: #{resp.body}")
        nil
      end

      def build_url(suffix)
        "#{base_versioned_url}/status/#{suffix}"
      end

      private

      def peers_url
        build_url('peers')
      end

      def leader_url
        build_url('leader')
      end

    end
  end
end