require 'gamz'
require_relative 'table'
require_relative 'game_handler'

class LobbyServer

  attr_reader :game_class, :player_class

  def initialize(game_class, player_class)
    @game_class, @player_class = game_class, player_class

    @service = Gamz::Net::Service.new self

    @names = {} # Client => client name
    @tables = {} # table name => Table
  end

  def start(control_port, notify_port)
    @service.listen control_port, notify_port
    @service.start
  end

  def client_name(client)
    @names[client] || "Client#{client.object_id}"
  end

  private

  def handle_set_name(client, name)
    @names[client] = name.to_s
    return :success
  end

  def handle_create_table(client, name)
    name = name.to_s
    @tables[name] = table = Table.new(self, name, client)
    client.state_handler = table

    @service.broadcast :table_created, table
    return :success
  end

  def handle_join_table(client, name)
    name = name.to_s
    if table = @tables[name]
      if !@game_class.max_players || table.clients.length < @game_class.max_players
        table.clients << client
        client.handler = table
        return :success
      else
        return :table_full
      end
    else
      return :invalid_table
    end
  end

end