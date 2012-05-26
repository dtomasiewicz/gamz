# implements the SERVER side of the WebSocket protocol only!

module Gamz
  module Protocol
    module WebSocket

      class Stream < Protocol::Stream

        def initialize(socket)
          super()
          @socket = socket
        end

        def to_io
          @socket
        end

        def do_read
          case @state
          when :open
            # TODO ping/pong/message?
            nil
          when :opening
            opening_handshake
            nil
          when :closing
            closing_handshake
            nil
          else
            # nil, closed
            raise "Invalid WebSockets read state: #{@state}"
          end
        end

        def open
          raise "WebSockets can only be opened once!" unless @state == nil
          super
          @state = :opening
        end

        def close
          raise "Cannot close non-open WebSocket." unless @state == :open
          super
          @state = :closing
        end

        private

        def opening_handshake
          # TODO
          @state = :open
          #open!
        end

        def closing_handshake
          # TODO
          @state = :closed
          #closed!
        end

      end

    end
  end
end