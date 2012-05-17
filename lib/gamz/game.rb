module Gamz

  class Game

    MIN_PLAYERS = 1
    MAX_PLAYERS = nil

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

    def self.min_players
      self::MIN_PLAYERS
    end

    def self.max_players
      self::MAX_PLAYERS
    end

    protected

    def rv(type, message = nil)
      RuleViolation.new type, message
    end

  end

end