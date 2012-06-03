require_relative 'game'
require_relative 'game_reactor'
require_relative 'table'

class Lobby

  include Gamz::Server::Reactor

  attr_reader :game_class, :player_class

  def initialize(server, game_class, player_class)
    @server, @game_class, @player_class = server, game_class, player_class

    @names = {} # Client => client name
    @tables = {} # table name => Table
  end

  def start
    old_reactor = @server.default_reactor
    @server.default_reactor = self
    @server.start
    @server.default_reactor = old_reactor
  end

  def client_name(client)
    @names[client] || "Client#{client.object_id}"
  end

  def destroy_table(name)
    if table = @tables.delete(name)
      table.clients.each do |c|
        c.notify :table_destroyed
        c.reactor = self
      end
      @server.broadcast :table_destroyed, table
    end
  end

  def on_connect(client)
    @server.broadcast :client_connect, client_name(client)
  end

  def on_disconnect(client)
    @names.delete client
    @server.broadcast :client_disconnect, client_name(client)
  end

  private

  def react_set_name(client, name)
    name = name.to_s
    if @names.has_value?(name)
      return :name_taken
    else
      @names[client] = name
      return :success
    end
  end

  def react_create_table(client, name)
    name = name.to_s
    return :table_exists if @tables[name]

    @tables[name] = table = Table.new(self, name, client)
    client.reactor = table

    @server.broadcast :table_created, table
    return :success
  end

  def react_join_table(client, name)
    name = name.to_s
    if table = @tables[name]
      if @game_class.max_players && table.clients.length >= @game_class.max_players
        return :table_full
      else
        table.clients.each {|c| c.notify :joined_table, client_name(client)}
        table.clients << client
        client.reactor = table
        return :success
      end
    else
      return :invalid_table
    end
  end

  def react_tables(client)
    # returns a hash of table_name => number_of_clients
    return :success, @tables.each_with_object({}) {|(n,t),h| h[n] = t.clients.length}
  end

end