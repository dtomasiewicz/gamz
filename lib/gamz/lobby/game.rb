module Gamz
  module Lobby

    class Game

      MIN_PLAYERS = 1
      MAX_PLAYERS = nil

      attr_accessor :players

      def initialize(players)
        @players = players
        @on_inform = nil
      end

      def on_inform(&block)
        @on_inform = block
      end

      def on_finished(&block)
        @on_finished = block
      end

      def player_left(player)
        @players.delete player
        inform_all :player_left, player
      end

      def self.min_players
        self::MIN_PLAYERS
      end

      def self.max_players
        self::MAX_PLAYERS
      end

      protected

      def inform(player, what, *details)
        if player.kind_of?(Array)
          player.each {|p| inform p, what, *details}
        else
          @on_inform.call player, what, *details if @on_inform
        end
      end

      def inform_all(*args)
        inform @players, *args
      end

      def inform_except(players, *args)
        players = [players] unless players.kind_of?(Array)
        inform @players-players, *args
      end

      def inform_others(what, player, *args)
        inform_except player, what, player, *args
      end

      def finished
        @on_finished.call if @on_finished
      end

    end
  end
end
