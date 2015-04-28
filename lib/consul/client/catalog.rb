require_relative 'base'
require_relative '../model/node'

# Consul Catalog End Point.
module Consul
  module Client
    class Catalog < Base

      # Public: Returns a list of all the nodes on this client
      #
      # dc - Data Center to look for services in, defaults to the agents data center
      #
      def nodes(dc = nil)
        params = {}
        params[:dc] = dc unless dc.nil?
        JSON.parse(_get build_url('nodes'), params).map {|n| Consul::Model::Node.new.extend(Consul::Model::Node::Representer).from_hash(n)}
      end

      # Public: Returns a list of services that are within the supplied or agent data center
      #
      # dc - Data Center to look for services in, defaults to the agents data center
      #
      # Example:
      #   Consul::Client::Catalog.new('dc1').services =>
      #   {
      #     "consul": [],
      #     "redis": [],
      #     "postgresql": [
      #       "master",
      #       "slave"
      #     ]
      #   }
      #
      # Returns: List of services ids.
      def services(dc = nil)
        params = {}
        params[:dc] = dc unless dc.nil?
        JSON.parse(_get build_url('services'), params)
      end

      # Public: Returns all the nodes within a data center that have the service specified.
      #
      # dc  - Data center, default: agent current data center
      # tag - Tag, filter for tags
      #
      # Example:
      #   ConsulCatalog.new('dc1').service('my_service_id') =>
      #     [ConsulNode<@service_id=my_service_id ...>,
      #      ConsulNode<@service_id=my_service_id ...>,
      #     ...]
      #
      # Returns: List of nodes that have this service.
      def service(id, dc = nil, tag = nil)
        params = {}
        params[:dc] = dc unless dc.nil?
        params.add[:tag] = tag unless tag.nil?
        JSON.parse(_get build_url("service/#{id}"), params).map {|n| Consul::Model::Node.new.extend(Consul::Model::Node::Representer).from_hash(n)}
      end

      # Public: Returns all the nodes within a data center that have the service specified.
      #
      # dc  - Data center, default: agent current data center
      # tag - Tag, filter for tags
      #
      # Example:
      #   ConsulCatalog.new('dc1').node('my_node') =>
      #     ConsulNode<@service_id=my_service_id ...>
      #
      # Returns: Returns the node by the argument name.
      def node(name, dc = nil)
        params = {}
        params[:dc] = dc unless dc.nil?
        resp = JSON.parse(_get build_url("node/#{name}"), params)
        n = Consul::Model::Node.new.extend(Consul::Model::Node::Representer).from_hash(resp['Node'])
        unless resp[:Services].nil?
          n.services = resp['Services'].keys.map{|k| Consul::Model::Service.new.extend(Consul::Model::Service::Representer).from_hash(resp[:Services][k])}
        end
        n
      end

      def data_centers
        _get build_url('datacenters'), params = nil, json_only = false
      end

      private

      # Public: Builds the base url
      #
      # Returns: The base
      def build_url(suffix)
        "#{base_versioned_url}/catalog/#{suffix}"
      end

    end
  end
end
