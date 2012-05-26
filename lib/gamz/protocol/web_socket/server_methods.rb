require 'gamz/protocol/web_socket'

module Gamz
  module Protocol
    module WebSocket

      module ServerMethods

        def listen_web_socket(*args)
          listener = Listener.new *args
          listener.on_accept {|c| add_client c}
          add_listener listener
        end
        alias_method :listen_ws, :listen_web_socket

      end

    end
  end
end

class Gamz::Server::Server
  include Gamz::Protocol::WebSocket::ServerMethods
end