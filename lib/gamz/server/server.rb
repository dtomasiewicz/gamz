require 'socket'

module Gamz
  module Server

    class Server

      attr_accessor :default_reactor, :suppress_reactor_errors

      def initialize(default_reactor = nil)
        @default_reactor = default_reactor

        @demux = Gamz::Demux.new
        # default read handler assumes a client control socket
        @demux.read &method(:read_stream)

        @clients = {} # stream => Client
        @suppress_reactor_errors = true

        @listens = {} # Socket => Protocol
        @addr_listens = {} # [port, host] => Socket

        # these reactors take precedence over client/default reactors
        @global_actions = {}
        @global_connect = @global_disconnect = nil
      end

      def global_connect(&block)
        @global_connect = bock
        self
      end
      alias_method :on_connect, :global_connect

      def global_action(action = nil, &block)
        action = action.to_s if action # allow symbols
        @global_actions[action] = block
        self
      end
      alias_method :on_action, :global_action

      def global_disconnect(&block)
        @global_disconnect = block
        self
      end
      alias_method :on_disconnect, :global_disconnect

      def listen(port, opts = {})
        host = opts[:host] || '0.0.0.0'
        protocol = opts[:protocol] || Gamz::Protocol::JSONSocket
        backlog = opts[:backlog] || 10

        raise "already listening on #{host}:#{port}" if @addr_listens[[port, host]]

        @addr_listens[[port, host]] = socket = Socket.new(:INET, :STREAM)
        @listens[socket] = protocol
        socket.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true
        socket.bind Socket.sockaddr_in(port, host)
        socket.listen backlog
        @demux.read socket, &method(:read_listen)

        self
      end

      def stop_listen(port, host = '0.0.0.0')
        if socket = @addr_listens.delete([port, host])
          @listens.delete socket
          @demux.stop_read socket
          socket.close
        end
        self
      end

      # only internally mutable
      def clients
        @clients.values
      end

      def disconnect(client)
        client.stream.close!
        self
      end

      def notify_all(*args)
        @clients.values.each {|c| c.notify *args}
        self
      end
      alias_method :broadcast, :notify_all

      # demux delegations

      def start(*args, &block)
        @demux.start *args, &block
        self
      end

      def at(*args, &block)
        @demux.at *args, &block
        self
      end

      def in(*args, &block)
        @demux.in *args, &block
        self
      end

      def in_scaled(*args, &block)
        @demux.in_scaled *args, &block
        self
      end

      private

      def read_listen(listen)
        socket, address = listen.accept_nonblock

        stream = @listens[listen].new socket do |stream|
          @clients[stream] = client = Client.new(stream, address)
          puts "[#{client.object_id}] CONNECT (#{address.ip_address}:#{address.ip_port})"

          # call connect handler
          if @global_connect
            @global_connect.call client
          elsif reactor = reactor_for(client)
            reactor.on_connect client if reactor.respond_to?(:on_connect)
          end
        end
        stream.on_closed &method(:stream_closed)

        @demux.read stream
      end

      def read_stream(stream)
        begin
          return unless message = stream.on_readable
          # client may have been forcibly disconnected during this step
          return unless client = @clients[stream]
          action, *data = message
        rescue => e
          print_error e
          return
        end

        puts "[#{client.object_id}] ACT #{action} => #{data}"

        begin
          res = dispatch client, action, data
          res = [res] unless res.kind_of?(Array)
        rescue => e
          raise e unless @suppress_reactor_errors
          print_error e
          res = [:reactor_error]
        end
        
        puts "[#{client.object_id}] RES #{res.first} => #{res[1..-1]}"

        begin
          client.respond *res
        rescue => e
          print_error e
        end
      end

      def stream_closed(stream)
        @demux.stop_read stream

        # client may not have been fully connected yet
        if client = @clients.delete(stream)
          client.stream = nil
          puts "[#{client.object_id}] DISCONNECT"

          # call disconnect handler
          if @global_disconnect
            @global_disconnect.call client
          elsif reactor = reactor_for(client)
            reactor.on_disconnect client if reactor.respond_to?(:on_disconnect)
          end
        end
      end

      def dispatch(client, action, data)
        if r = @global_actions[action]
          return r.call client, *data
        elsif reactor = reactor_for(client)
          return reactor.on_action client, action, *data
        else
          return :invalid_action
        end
      end

      def print_error(error)
        puts "  #{error.inspect}"
        puts "  #{error.backtrace.first}"
      end

      def reactor_for(client)
        client.reactor || @default_reactor
      end

    end

  end
end