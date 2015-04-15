require 'representable/json'
require 'ostruct'
require_relative 'health_check'

module Consul
  module Model

    # Consul Service Representation.
    class Service < OpenStruct
      module Representer
        include Representable::JSON
        include Representable::Hash
        include Representable::Hash::AllowSymbols

        # Attributes that can be both configured as well read.
        property :id, as: :ID
        property :service, as: :Service
        property :tags, as: :Tags
        property :address, as: :Address
        property :port, as: :Port

        # Attributes only defined at initialization time
        property :name, as: :Name
        property :check, as: :Check, extend: Consul::Model::HealthCheck::Representer, class: Consul::Model::HealthCheck
      end
      extend Representer

      def self.for_name(name, check = nil)
        raise ArgumentError.new "Illegal name: \"#{name}\" for service." if name.nil?
        unless check.nil? or check.is_a?(Consul::Model::HealthCheck)
          raise TypeError.new "Illegal Check type: #{check}.  Expecting Consul::Model::HealthCheck"
        end
        if check.nil?
          Consul::Model::Service.new(name: name)
        else # There is a health check to register
          Consul::Model::Service.new(name: name, check: check)
        end
      end

      # Public: Creates a health check meant to be used when registering a service.
      def self.script_health_check(script, interval)
        Consul::Model::HealthCheck.new(script: script, interval: interval)
      end

      def self.http_health_check(http, interval)
        Consul::Model::HealthCheck.new(http: http, interval: interval)
      end

      def self.ttl_health_check(ttl)
        Consul::Model::HealthCheck.new(ttl: ttl)
      end

    end
  end
end
