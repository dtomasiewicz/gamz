class Table

  include Gamz::Server::Reactor

  attr_accessor :name, :owner, :clients

  def initialize(lobby, name, owner)
    @lobby, @name, @owner = lobby, name, owner
    @clients = [owner]
  end

  def on_disconnect(client)
    drop_client client
    @lobby.on_disconnect client
  end

  def to_s
    @name
  end

  private

  def drop_client(client)
    client.reactor = @lobby
    @clients.delete client
    @clients.each {|c| c.notify :left_table, @lobby.client_name(client)}
    if client == @owner
      if @owner = @clients.first
        # still at least 1 client at the table
        @clients.each do |c|
          if c == @owner
            c.notify :own_table
          else
            c.notify :table_owner, @lobby.client_name(@owner)
          end
        end
      else
        # no clients left at table
        @lobby.destroy_table self.name
      end
    end
  end

  def react_leave_table(client)
    drop_client client
    return :success
  end

  def react_start_game(client)
    if @owner == client
      if @clients.length >= @lobby.game_class.min_players
        # create players
        players = []
        player_clients = {}

        @clients.each do |client|
          players << @lobby.player_class.new(@lobby.client_name client)
          player_clients[players.last] = client
          client.notify :game_started
        end

        # create game
        game = @lobby.game_class.new players
        game.on_inform do |player, what, *details|
          player_clients[player].notify what, *details
        end
        game.on_finished do
          @clients.each {|c| c.reactor = self}
        end
        game.setup

        # set player reactors
        reactor = GameReactor.new self, game, player_clients.invert
        @clients.each {|c| c.reactor = reactor}

        return :success
      else
        return :not_enough_players
      end
    else
      return :invalid_action
    end
  end
  
end