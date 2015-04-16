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

    end
  end
end
