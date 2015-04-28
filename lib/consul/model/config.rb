require 'representable/json'
require 'ostruct'

module Consul
  module Model
    # Consul Config Object Representation
    #
    # Reference:  https://www.consul.io/docs/agent/http/agent.html#agent_self
    #
    class Config < OpenStruct
      module Representer
        include Representable::JSON
        include Representable::Hash
        include Representable::Hash::AllowSymbols

        property :bootstrap, as: :Bootstrap
        property :server, as: :Server
        property :datacenter, as: :Datacenter
        property :datadir, as: :DataDir
        property :dns_recursor, as: :DNSRecursor
        property :dns_recursors, as: :DNSRecursors
        property :domain, as: :Domain
        property :log_level, as: :LogLevel
        property :node_name, as: :NodeName
        property :client_addr, as: :ClientAddr
        property :bind_addr, as: :BindAddr
        property :advertise_addr, as: :AdvertiseAddr
        property :ports, as: :Ports
        property :leave_on_term, as: :LeaveOnTerm
        property :skip_leave_on_int, as: :SkipLeaveOnInt
        property :stat_site_addr, as: :StatsiteAddr
        property :protocol, as: :Protocol
        property :enable_debug, as: :EnableDebug
        property :verify_incoming, as: :VerifyIncoming
        property :verify_outgoing, as: :VerifyOutgoing
        property :ca_file, as: :CAFile
        property :cert_file, as: :CertFile
        property :key_file, as: :KeyFile
        property :start_join, as: :StartJoin
        property :ui_dir, as: :UiDir
        property :pid_file, as: :PidFile
        property :enable_syslog, as: :EnableSyslog
        property :rejoin_after_leave, as: :RejoinAfterLeave

      end
      extend Representer
    end
  end
end
