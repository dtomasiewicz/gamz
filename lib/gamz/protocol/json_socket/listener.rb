module Gamz
  module Protocol
    module JSONSocket

      class Listener < Protocol::Socket::Listener

        protected

        def construct_client(socket, address)
          Protocol::Socket::Client.new Stream.new(socket), address
        end

      end

    end
  end
end