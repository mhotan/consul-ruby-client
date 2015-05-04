require_relative 'base'

module Consul
  module Client

    # Represents Consul Health Check
    #
    # http://www.consul.io/docs/agent/http/health.html
    #
    class HealthCheck < Base

      # Public return the health checks that correspond to
      def node(node, opts = {})

      end

      def checks(service, opts = {})

      end

    end
  end
end
