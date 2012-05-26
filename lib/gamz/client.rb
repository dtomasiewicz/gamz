require 'gamz'

module Gamz

  module Client

    def self.new(*args, &block)
      Client.new *args, &block
    end

  end

end

require 'gamz/client/client'
require 'gamz/client/input_stream'