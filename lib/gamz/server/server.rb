require 'socket'

module Gamz
  module Server

    class Server

      attr_accessor :default_reactor, :encoder, :suppress_reactor_errors

      def initialize(default_reactor = nil, encoder = Gamz::Marshal::JSONBinary.new)
        @default_reactor = default_reactor
        @encoder = encoder

        @demux = Gamz::Demux.new
        # default read handler assumes a client control socket
        @demux.read &method(:read_client)

        @clients = {} # control_sock => ServiceClient
        @suppress_reactor_errors = true

        @control_l = @notify_l = nil
        @notify_anon = {} # claim_key => [sock, addr]

        # these reactors take precedence over client/default reactors
        @global_actions = {}
        @global_connect = @global_disconnect = nil

        global_action :claim_notify, &method(:claim_notify)
      end

      def global_connect(&block)
        @global_connect = bock
      end
      alias_method :on_connect, :global_connect

      def global_action(action = nil, &block)
        action = action.to_s if action # allow symbols
        @global_actions[action] = block
      end
      alias_method :on_action, :global_action

      def global_disconnect(&block)
        @global_disconnect = block
      end
      alias_method :on_disconnect, :global_disconnect

      def listen(control_port, notify_port, backlog = 10)
        @control_l = open_listener control_port, backlog, method(:read_control)
        @notify_l = open_listener notify_port, backlog, method(:read_notify)

        self
      end

      def stop_listen
        @notify_l = close_listener @notify_l
        @control_l = close_listener @control_l

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

      def notify_all(type, *data)
        @clients.values.each {|c| c.notify type, *data}

        self
      end
      alias_method :broadcast, :notify_all

      private

      def open_listener(port, backlog, handler)
        sock = Socket.new :INET, :STREAM
        sock.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true
        sock.bind Addrinfo.tcp("127.0.0.1", port)
        sock.listen backlog
        @demux.read sock, &handler

        sock
      end

      def close_listener(sock)
        @demux.stop_read sock
        sock.close

        nil
      end

      def read_control
        client = Client.new self, *@control_l.accept_nonblock
        @clients[client.control_sock] = client
        @demux.read client.control_sock

        # call connect handler
        if @global_connect
          @global_connect.call client
        elsif reactor = reactor_for(client)
          reactor.on_connect client if reactor.respond_to?(:on_connect)
        end
      end

      def read_notify
        sock = @notify_l.accept_nonblock[0]
        @notify_anon[claim_key = gen_claim_key] = sock
        begin
          @encoder.send_message sock, :claim_key, claim_key
        rescue => e
          puts "ERROR: Failed to send claim key (#{e.inspect})"
        end
      end

      def read_client(sock)
        client = @clients[sock]

        begin
          action, *data = @encoder.recv_message sock
        rescue Gamz::Marshal::SocketClosed
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
          @encoder.send_message client.control_sock, *res
        rescue => e
          print_error e
        end
      end

      def gen_claim_key
        # TODO improve this
        claim_key = (0...40).map{(65 + rand(25)).chr}.join
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

      def claim_notify(client, key)
        if @notify_anon.has_key?(key)
          client.notify_sock.close if client.notify_sock
          client.notify_sock = @notify_anon.delete key
          return :success
        else
          return :invalid_claim_key
        end
      end

      def disconnect(client)
        @demux.stop_read client.control_sock
        @clients.delete client.control_sock
        client.control_sock.close
        client.notify_sock.close
        client.control_sock = client.notify_sock = nil
        puts "[#{client.object_id}] DIS"

        # call disconnect handler
        if @global_disconnect
          @global_disconnect.call client
        elsif reactor = reactor_for(client)
          reactor.on_disconnect client if reactor.respond_to?(:on_disconnect)
        end
      end

      def reactor_for(client)
        client.reactor || @default_reactor
      end

    end

  end
end