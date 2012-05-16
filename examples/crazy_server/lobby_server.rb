require 'gamz'
require_relative 'table'
require_relative 'game_handler'

class LobbyServer

  attr_reader :game_class, :player_class

  def initialize(game_class, player_class)
    @game_class, @player_class = game_class, player_class
    @server = Gamz::Net::Service.new
    # allow client name to be set at any time
    @server.handle :set_name, &method(:handle_set_name)
    @names = {} # Client => client name
    @tables = {} # table name => Table
  end

  def start(control_port, notify_port)
    @server.listen control_port, notify_port
    @server.default_handler = self
    @server.start
  end

  def client_name(client)
    @names[client] || "Client#{client.object_id}"
  end

  private

  def handle_set_name(client, name)
    @names[client] = name.to_s
    client.respond :success
  end

  def handle_create_table(client, name)
    name = name.to_s
    @tables[name] = table = Table.new(self, name, client)
    client.handler = table

    @server.broadcast :table_created, table
    client.respond :success
  end

  def handle_join_table(client, name)
    name = name.to_s
    if table = @tables[name] && table.clients.length < @game_class::MAX_PLAYERS
      table.clients << client
      client.handler = table
      client.respond :success
    else
      client.respond :error, 'invalid table'
    end
  end

end