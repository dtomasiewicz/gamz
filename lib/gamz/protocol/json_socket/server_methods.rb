require 'gamz/protocol/json_socket'

module Gamz
  module Protocol
    module JSONSocket

      module ServerMethods

        def listen_socket(*args)
          listener = Listener.new *args
          listener.on_accept {|c| add_client c}
          add_listener listener
        end
        alias_method :listen, :listen_socket

      end

    end
  end
end

class Gamz::Server::Server
  include Gamz::Protocol::JSONSocket::ServerMethods
end