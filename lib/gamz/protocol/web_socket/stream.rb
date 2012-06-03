require 'lib_web_sockets'
require 'json'

# implements the SERVER side of the WebSocket protocol only!
module Gamz
  module Protocol
    module WebSocket

      class Stream < Protocol::Socket::Stream

        def send_message(msg)
          @ws.send JSON.dump(msg)
        end

        def do_read
          begin
            @ws.recv
          rescue => e
            puts e.inspect
            puts e.backtrace[0]
            socket.close
            closed!
          end
        end

        def ping(*args, &block)
          @ws.ping *args, &block
        end

        def open
          super

          @ws = LibWebSockets::ServerConnection.new(socket) do |message|
            message! JSON.parse(message) rescue close
          end
          @ws.on_open { open! }
          @ws.on_close { closed! }
        end

        def close
          super
          @ws.close
        end

      end

    end
  end
end