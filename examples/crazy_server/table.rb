require_relative 'game_reactor'

class Table

  include Gamz::Net::Reactor

  attr_accessor :name, :owner, :clients

  def initialize(lobby, name, owner)
    @lobby, @name, @owner = lobby, name, owner
    @clients = [owner]
  end

  def to_s
    @name
  end

  private

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
        game.setup

        # set player reactors
        reactor = GameReactor.new game, player_clients.invert
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