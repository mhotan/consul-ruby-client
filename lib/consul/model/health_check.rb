require 'representable/json'
require 'ostruct'

module Consul
  module Model

    # Consul Health Check
    #
    # Reference: https://www.consul.io/docs/agent/checks.html
    #
    class HealthCheck < OpenStruct
      module Representer
        include Representable::JSON
        include Representable::Hash
        include Representable::Hash::AllowSymbols

        # Property Common for registering and reading
        property :name, as: :Name
        property :notes, as: :Notes

        # Properties used for registration
        property :id, as: :ID
        property :script, as: :Script
        property :http, as: :HTTP
        property :interval, as: :Interval
        property :ttl, as: :TTL

        # Properties used for reading.
        property :node, as: :Node
        property :check_id, as: :CheckID
        property :status, as: :Status
        property :output, as: :Output
        property :service_id, as: :ServiceID
        property :service_name, as: :ServiceName
      end
      extend Representer
    end
  end
end
