require_relative 'base'
require_relative '../model/session'
require_relative '../util/utils'

module Consul
  module Client
    # Consul Session Client
    class Session
      include Consul::Client::Base

      # Public: Creates a new Consul Session.
      #
      # session - Session to create.
      # dc      - Consul data center
      #
      # Returns The Session ID a
      def create(session, dc = nil)
        raise TypeError, 'Session must be of type Consul::Model::Session' unless session.kind_of? Consul::Model::Session
        params = {}
        params[:dc] = dc unless dc.nil?
        success, body = put(build_url('create'), session, params)
        return Consul::Model::Session.new.extend(Consul::Model::Service::Representer).from_json(body) if success
        logger.warn("Unable to create session with #{session}")
        nil
      end

      # Public: Destroys a given session
      # def destroy(session_name)
      #   success, body = put build_url("destroy/#{session_name}")
      # end

      # Public: Return the session info for a given session name.
      #
      def info(session_name, dc = nil)
        params = {}
        params[:dc] = dc unless dc.nil?
        resp = get build_url("info/#{session_name}"), params
        JSON.parse(resp).map{|session_hash| session(session_hash)} unless resp.nil?
      end

      # Lists sessions belonging to a node
      def node(session_name, dc = nil)
        params = {}
        params[:dc] = dc unless dc.nil?
        resp = get build_url("node/#{session_name}"), params
        JSON.parse(resp).map{|session_hash| session(session_hash)} unless resp.nil?
      end

      # Lists all active sessions
      def list(dc = nil)
        params = {}
        params[:dc] = dc unless dc.nil?
        resp = get build_url('list'), params
        JSON.parse(resp).map{|session_hash| session(session_hash)} unless resp.nil?
      end

      # Renews a TTL-based session
      def renew(session, dc = nil)
        raise ArgumentError, 'Session does not have name' if session.name.nil?
        params = {}
        params[:dc] = dc unless dc.nil?
        success, _ = put build_url("renew/#{session.name}"), session.to_json
        success
      end

      private

      def session(obj)
        if Consul::Utils.valid_json?(obj)
          Consul::Model::Session.new.extend(Consul::Model::Session::Representer).from_json(obj)
        elsif obj.is_a?(Hash)
          Consul::Model::Session.new.extend(Consul::Model::Session::Representer).from_hash(obj)
        end
      end

      # Private: Create the url for a session endpoint.
      #
      # suffix - Suffix of the url endpoint
      #
      # Return: The URL for a reachable endpoint
      def build_url(suffix)
        "#{base_versioned_url}/session/#{suffix}"
      end

    end
  end
end
