class GameReactor

  def initialize(table, game, client_players)
    @table, @game, @client_players = table, game, client_players
  end

  def on_disconnect(client)
    @game.player_left @client_players[client]
    @table.on_disconnect client
  end

  def on_action(client, action, *data)
    if @game.respond_to?(m = :"do_#{action}")
      return @game.send m, @client_players[client], *data
    else
      return :invalid_action
    end
  end

end