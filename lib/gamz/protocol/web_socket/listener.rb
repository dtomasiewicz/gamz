module Gamz
  module Protocol
    module WebSocket

      class Listener < Protocol::Socket::Listener

        protected

        def create_client(socket, address)
          Protocol::Socket::Client.new Stream.new(socket), address
        end

      end

    end
  end
end