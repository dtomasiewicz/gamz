require 'gamz'
require 'gamz/server'

module Gamz
  
  module Lobby

    def self.new(*args, &block)
      Lobby.new *args, &block
    end

  end

end

require 'gamz/lobby/lobby'
require 'gamz/lobby/table'
require 'gamz/lobby/game'
require 'gamz/lobby/game_reactor'