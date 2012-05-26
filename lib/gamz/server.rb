require 'gamz'

module Gamz

  module Server

    def self.new(*args, &block)
      Server.new *args, &block
    end

  end

end

require 'gamz/listener'
require 'gamz/server/server'
require 'gamz/server/client'
require 'gamz/server/reactor'