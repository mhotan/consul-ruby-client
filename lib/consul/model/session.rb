require 'representable/json'
require 'ostruct'

module Consul
  module Model

    # Consul Session representation.
    class Session < OpenStruct
      module Representer
        include Representable::JSON
        include Representable::Hash
        include Representable::Hash::AllowSymbols

        # Properties that are intended to be written by clients.
        property :lock_delay, as: :LockDelay
        property :name, as: :Name
        property :node, as: :Node
        collection :checks, as: :Checks
        property :behaviour, as: :Behavior
        property :ttl, as: :TTL

        # Properties that exclusively read access.
        property :id, as: :ID
        property :create_index, as: :CreateIndex
      end
      extend Representer
    end

  end
end
