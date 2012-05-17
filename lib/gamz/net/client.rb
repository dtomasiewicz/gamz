module Gamz
	module Net

		class Client

      attr_accessor :encoder

      def initialize(encoder = Net::Marshal::JSONBinary.new)
        @encoder = encoder
        @demux = Demux.new
        @control = @notify = nil
        @response_handlers = []
        @notify_handlers = {}
        @input_handler = nil

        on_notify :claim_key, &method(:claim_notify)
      end

      def on_notify(type = nil, &block)
        type = type.to_s if type # allow symbols
        @notify_handlers[type] = block
      end

      def on_input(&block)
        @input_handler = block
      end

      def connect(control_port, notify_port)
        @control = open_conn control_port, method(:read_control)
        @notify = open_conn notify_port, method(:read_notify)

        self
      end

      def disconnect
        @notify = close_conn @notify
        @control = close_conn @control

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
        @encoder.send_message @control, action, *data

        self
      end

      private

      def claim_notify(key)
        act :claim_notify, key do |res|
          if res == 'success'
            puts "NOTIFY CONNECTION CLAIMED"
          else
            puts "FAILED TO CLAIM NOTIFY CONNECTION: #{res}"
          end
        end
      end

      def open_conn(port, read_handler)
        sock = Socket.new :INET, :STREAM
        sock.connect Addrinfo.tcp('127.0.0.1', port)
        @demux.read sock, &read_handler

        sock
      end

      def close_conn(sock)
        @demux.stop_read sock
        sock.close

        nil
      end

      def read_control
        if handler = @response_handlers.shift
          handler.call *@encoder.recv_message(@control)
        end
      end

      def read_notify
        type, *data = @encoder.recv_message @notify
        if @notify_handlers[type]
          @notify_handlers[type].call *data
        elsif @notify_handlers[nil]
          @notify_handlers[nil].call type, *data
        else
          raise "no suitable notify handler for #{type}"
        end
      end

      def read_input
        input = STDIN.gets
        @input_handler.call input if @input_handler
      end

		end

  end
end
