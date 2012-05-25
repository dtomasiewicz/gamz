require 'socket'

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

      def connect(port, opts = {})
        host = opts[:host] || '0.0.0.0'
        protocol = opts[:protocol] || Gamz::Protocol::JSONSocket

        socket = Socket.new :INET, :STREAM
        socket.connect Socket.sockaddr_in(port, host)
        @demux.read socket, &method(:read_socket)
        @stream = protocol.new socket

        self
      end

      def disconnect
        @demux.stop_read @stream.socket
        @stream.socket.close
        @stream = nil

        self
      end

      def start(timeout = nil, &block)
        @demux.read STDIN, &method(:read_input)
        @demux.start timeout, &block
        @demux.stop_read STDIN

        self
      end

      def act(action, *data, &block)
        @response_handlers << block
        @stream.send action, *data

        self
      end

      private

      def read_socket(socket)
        id, *data = @stream.on_readable
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
