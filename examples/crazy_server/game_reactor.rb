class GameReactor

  def initialize(game, players)
    @game = game
    @players = players # Client => Player
  end

  def react(client, action, *data)
    if @game.respond_to?(m = :"do_#{action}")
      begin
        @game.send m, @players[client], *data
        return :success
      rescue Gamz::RuleViolation => rv
        return rv.type
      end
    else
      return :invalid_action
    end
  end

end