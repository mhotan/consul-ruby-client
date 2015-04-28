require 'representable/json'
require 'ostruct'

module Consul
  module Model

    # Consul Member representation
    #
    # Reference: https://www.consul.io/docs/commands/members.html
    #
    class Member < OpenStruct
      module Representer
        include Representable::JSON
        include Representable::Hash
        include Representable::Hash::AllowSymbols

        property :name, as: :Name
        property :addr, as: :Addr
        property :port, as: :Port
        # TODO Ensure we map tags into a ruby hash and back
        property :tags, as: :Tags
        property :status, as: :Status
        property :protocol_min, as: :ProtocolMin
        property :protocol_max, as: :ProtocolMax
        property :protocol_cur, as: :ProtocolCur
        property :delegate_min, as: :DelegateMin
        property :delegate_max, as: :DelegateMax
        property :delegate_cur, as: :DelegateCur
      end
      extend Representer
    end
  end
end
