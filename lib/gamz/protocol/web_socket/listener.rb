module Gamz
  module Protocol
    module WebSocket

      class Listener < Protocol::Socket::Listener

        protected

        def construct_client(socket, address)
          Client.new Stream.new(socket), address
        end

      end

    end
  end
end