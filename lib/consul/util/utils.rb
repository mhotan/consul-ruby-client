require 'json'

module Consul
  class Utils

    # Public verify this is valid json
    def self.valid_json?(json)
      begin
        JSON.parse(json)
        return true
      rescue Exception => e
        return false
      end
    end

  end
end
