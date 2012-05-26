require 'gamz'

module Gamz

  module Server

    def self.new(*args, &block)
      Server.new *args, &block
    end

  end

end

require 'gamz/server/server'
require 'gamz/server/reactor'

# default protocol implementations
require 'gamz/protocol/json_socket/server_methods'
require 'gamz/protocol/web_socket/server_methods'