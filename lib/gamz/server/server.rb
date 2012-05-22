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

      def start(timeout = nil, &block)
        @demux.start timeout, &block

        self
      end

      # only internally mutable
      def clients
        @clients.values
      end

      def disconnect(client)
        @demux.stop_read client.stream
        @clients.delete client.stream
        client.stream.close
        client.stream = nil
        puts "[#{client.object_id}] DISCONNECT"

        # call disconnect handler
        if @global_disconnect
          @global_disconnect.call client
        elsif reactor = reactor_for(client)
          reactor.on_disconnect client if reactor.respond_to?(:on_disconnect)
        end

        self
      end

      def notify_all(*args)
        @clients.values.each {|c| c.notify *args}

        self
      end
      alias_method :broadcast, :notify_all

      private

      def read_listen(listen)
        socket, address = listen.accept_nonblock
        stream = @listens[listen].new socket
        @demux.read stream

        stream.on_io_ready do
          @clients[stream] = client = Client.new(stream, address)
          puts "[#{client.object_id}] CONNECT (#{address.ip_address}:#{address.ip_port})"
          # call connect handler
          if @global_connect
            @global_connect.call client
          elsif reactor = reactor_for(client)
            reactor.on_connect client if reactor.respond_to?(:on_connect)
          end
        end
      end

      def read_stream(stream)
        unless stream.io_ready?
          stream.initialize_io
          return
        end

        # it's possible the client may have already been disconnected during the same tick
        return unless client = @clients[stream]

        begin
          action, *data = client.read
        rescue Gamz::Protocol::NoData
          # socket was closed remotely
          disconnect client
          return
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