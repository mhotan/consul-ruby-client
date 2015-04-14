require 'representable/json'
require 'ostruct'

module Consul
  module Model

    # Consul Key Value representation
    #
    # Reference: https://www.consul.io/intro/getting-started/kv.html
    #
    class KeyValue < OpenStruct
      module Representer
        include Representable::JSON
        include Representable::Hash
        include Representable::Hash::AllowSymbols

        property :create_index, as: :CreateIndex
        property :modify_index, as: :ModifyIndex
        property :lock_index, as: :LockIndex
        property :key, as: :Key
        property :flags, as: :Flags
        property :value, as: :Value
        property :session, as: :Session
      end
      extend Representer
    end
  end
end
