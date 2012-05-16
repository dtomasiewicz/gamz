module Gamz

  class Game

    attr_accessor :players

    def initialize(players)
      @players = players
      @informer = nil
    end

    def on_inform(&block)
      @informer = block
    end

    def inform(player, what, *details)
      if player.kind_of?(Array)
        player.each {|p| inform p, what, *details}
      else
        @informer.call player, what, *details if @informer
      end
    end

    def inform_all(*args)
      inform @players, *args
    end

    def inform_except(players, *args)
      players = [players] unless players.kind_of?(Array)
      inform @players-players, *args
    end

    protected

    def rv(type, message = nil)
      RuleViolation.new type, message
    end

  end

end