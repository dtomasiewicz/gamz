module Gamz
  module Server

    class Server

      attr_accessor :default_reactor, :suppress_reactor_errors

      def initialize(default_reactor = nil)
        @default_reactor = default_reactor

        @demux = Gamz::Demux.new
        @clients = {} # stream => Client
        @suppress_reactor_errors = true

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

      def add_listener(listener)
        listener.open
        @demux.add listener
        self
      end

      def remove_listener(listener)
        @demux.remove listener
        listener.close
        self
      end

      # note: @clients should never be externally mutable
      def clients
        @clients.values
      end

      def add_client(client)
        client.stream.on_closed &method(:stream_closed)
        client.stream.open do |stream|
          @clients[stream] = client
          stream.on_message &method(:dispatch)

          puts "[#{client}] CONNECT"

          # call connect handler
          if @global_connect
            @global_connect.call client
          elsif reactor = reactor_for(client)
            reactor.on_connect client if reactor.respond_to?(:on_connect)
          end
        end

        @demux.add client.stream
        self
      end
      alias_method :<<, :add_client

      def remove_client(client)
        client.stream.close # on_closed is already set to &:stream_closed
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

      def seconds(*args, &block)
        @demux.seconds *args, &block
        self
      end

      def ticks(*args, &block)
        @demux.ticks *args, &block
        self
      end

      def each_seconds(*args, &block)
        @demux.each_seconds *args, &block
        self
      end

      def each_ticks(*args, &block)
        @demux.each_ticks *args, &block
        self
      end

      def cleanup
        @clients.each_value do |client|
          remove_client client
        end
      end

      private

      def stream_closed(stream)
        @demux.remove stream

        # client may not have been fully connected yet
        if client = @clients.delete(stream)
          puts "[#{client.object_id}] DISCONNECT"

          # call disconnect handler
          if @global_disconnect
            @global_disconnect.call client
          elsif reactor = reactor_for(client)
            reactor.on_disconnect client if reactor.respond_to?(:on_disconnect)
          end
        end
      end

      def dispatch(stream, data)
        client = @clients[stream]
        action, *data = data

        puts "[#{client.object_id}] ACT #{action} => #{data}"

        begin
          if r = @global_actions[action]
            res = r.call client, *data
          elsif reactor = reactor_for(client)
            res = reactor.on_action client, action, *data
          else
            res = [:invalid_action]
          end
        rescue => e
          raise e unless @suppress_reactor_errors
          print_error e
          res = [:reactor_error]
        end
        
        res = [res] unless res.kind_of?(Array)
        puts "[#{client.object_id}] RES #{res.first} => #{res[1..-1]}"

        begin
          client.respond *res
        rescue => e
          print_error e
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