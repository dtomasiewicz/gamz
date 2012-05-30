require 'gamz'
require 'gamz/protocol/json_socket'

module Gamz
  module Client

  	class Client

      def initialize
        @demux = Gamz::Demux.new
        @stream = nil
        @response_handlers = []
        @notify_handlers = {}
        @input_handler = nil
      end

      def on_notify(id = nil, &block)
        id = id.to_s if id # allow symbols
        @notify_handlers[id] = block

        self
      end

      def on_input(&block)
        @input_handler = block

        self
      end

      def open(port, opts = {})
        host = opts[:host] || '0.0.0.0'

        socket = Socket.new :INET, :STREAM
        socket.connect Socket.sockaddr_in(port, host)
        @stream = Gamz::Protocol::JSONSocket::Stream.new socket
        @stream.on_message &method(:dispatch)
        @demux.add @stream

        self
      end

      def close
        @demux.stop_read @stream.socket
        @stream.socket.close
        @stream = nil

        self
      end

      def start(timeout = nil, &block)
        input = InputStream.new STDIN, &method(:read_input)
        @demux.add input
        @demux.start timeout, &block
        @demux.remove input

        self
      end

      def act(action, *data, &block)
        @response_handlers << block
        @stream.send_message [action, *data]

        self
      end

      private

      def dispatch(stream, data)
        id, *data = data
        rel, id = id.split '_', 2
        if rel == 'n'
          if h = @notify_handlers[id]
            h.call *data
          elsif h = @notify_handlers[nil]
            h.call id, *data
          else
            raise "no suitable notify handler for #{id}"
          end
        elsif h = @response_handlers.shift
          h.call id, *data
        end
      end
      
      def read_input(input)
        input = input.gets
        @input_handler.call input if @input_handler
      end

    end

  end
end
