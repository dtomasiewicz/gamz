module Gamz
  module Protocol
    module WebSocket

      class Client < Protocol::Socket::Client

        def ping(*args, &block)
          stream.ping *args, &block
        end

      end

    end
  end
end