require_relative 'base'

module Consul
  module Client
    class Status
      include Consul::Client::Base

      # Public: This endpoint is used to get the Raft leader for the
      # datacenter in which the agent is running
      #
      # Reference: https://www.consul.io/docs/agent/http/status.html
      #
      # Returns: Address, host:port.
      def leader
        RestClient.get leader_url
      end

      # Public: This endpoint retrieves the Raft peers for the
      # datacenter in which the the agent is running
      #
      # Reference: https://www.consul.io/docs/agent/http/status.html
      #
      # Returns: List of addresses.
      def peers
        RestClient.get peers_url
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