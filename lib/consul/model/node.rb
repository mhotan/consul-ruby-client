require 'representable/json'
require 'ostruct'

module Consul
  module Model

    # Consul Node Representation.
    class Node < OpenStruct
      module Representer
        include Representable::JSON
        include Representable::Hash
        include Representable::Hash::AllowSymbols

        property :node, as: :Node
        property :address, as: :Address
        property :service_id, as: :ServiceID
        property :service_name, as: :ServiceName
        property :service_tags, as: :ServiceTags
        property :service_address, as: :ServiceAddress
        property :service_port, as: :ServicePort
      end
      extend Representer
    end
  end
end
