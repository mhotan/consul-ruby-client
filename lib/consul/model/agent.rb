require 'representable/json'
require 'ostruct'
require_relative 'config'
require_relative 'member'

module Consul
  module Model
    # Agent Model class
    #
    # Common use case Agent.self
    #
    # Reference: https://www.consul.io/docs/agent/http/agent.html#agent_self
    #
    class Agent < OpenStruct
      module Representer
        include Representable::JSON
        include Representable::Hash
        include Representable::Hash::AllowSymbols

        property :config, as: :Config, extend: Consul::Model::Config::Representer, class: Consul::Model::Config
        property :member, as: :Member, extend: Consul::Model::Member::Representer, class: Consul::Model::Member
      end
      extend Representer
    end
  end
end
