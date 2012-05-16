require 'set'
require 'socket'

module Gamz
  module Net

    class Service

      DEFAULT_TICK_RATE = 60

      attr_accessor :default_handler, :tick_rate, :encoder, :suppress_handler_errors

      def initialize(encoder = Net::Marshal::JSONBase64.new)
        @encoder = encoder

        @suppress_handler_errors = true
        @clients = {} # control_sock => Client
        @selectable = []

        @control_srv = Socket.new :INET, :STREAM
        @control_srv.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true
        @notify_srv = Socket.new :INET, :STREAM
        @notify_srv.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true

        @notify_anon = {} # claim_key => [sock, addr]
        @running = false

        @tick_rate = DEFAULT_TICK_RATE
        @timer = []
        @schedule = []

        @global_handlers = {}
        @default_handler = nil
        handle :claim_notify, &method(:claim_notify)
      end

      # schedule execution of the passed block to occur in at least <seconds>
      # - the actual time elapsed before execution scales with load (more
      #   load = more skew)
      # - implemented backwards to allow use of pop instead of shift in #start

      def in(seconds, &block)
        ticks = (seconds*@tick_rate).round
        if @timer.empty?
          @timer << [ticks, block]
        else
          # insert somewhere other than the end
          i = @timer.length-1
          while i >= 0 && @timer[i][0] <= ticks
            ticks -= @timer[i][0]
            i -= 1
          end
          # adjust predecessor
          @timer[i][0] -= ticks if i >= 0
          @timer.insert i+1, [ticks, block]
        end
      end

      # schedule execution of the passed block at the given <time> (or as soon
      # afterwards as possible)
      # - the actual time elapsed before execution does NOT scale with load
      # - implemented backwards to allow use of pop instead of shift in #start

      def at(time, &block)
        if @schedule.empty?
          @schedule << [time, block]
        else
          i = @schedule.length-1
          i -= 1 while i >= 0 && @schedule[i][0] <= time
          @schedule.insert i+1, [time, block]
        end
      end

      def handle(action = nil, &block)
        action = action.to_s if action # allow symbols
        if block
          @global_handlers[action] = block
        else
          @global_handlers.delete action
        end
      end

      def listen(control_port, notify_port, backlog = 10)
        raise "server is already running" if @running
        @control_srv.bind Addrinfo.tcp("127.0.0.1", control_port)
        @control_srv.listen backlog
        @notify_srv.bind Addrinfo.tcp("127.0.0.1", notify_port)
        @notify_srv.listen backlog
        @selectable << @control_srv << @notify_srv
        self
      end

      # if <timeout> is given without a bock, server will run for at least that many
      # seconds before this method returns.
      #
      # if <timeout> is given along with a block, the server will run for at least
      # <timeout> seconds, then execute the block and run for <timeout> seconds again 
      # if the block returns a true value, repeating until the block returns a false
      # value
      #
      # if no timeout is given, the server will run until interrupted

      def start(timeout = nil, &block)
        raise "server is already running" if @running
        step_timeout = 1.0/@tick_rate
        ticks = timeout ? (timeout*@tick_rate).round : nil

        each_tick = Proc.new do
          start = Time.now
          step step_timeout
          @schedule.pop[1].call until @schedule.empty? || @schedule.last[0] > Time.now
          @timer.last[0] -= 1 unless @timer.empty?
          @timer.pop[1].call until @timer.empty? || @timer.last[0] > 0
        end

        @running = true
        if timeout
          while @running
            (timeout*@tick_rate).round.times &each_tick
            @running = block_given? ? yield : false
          end
        else
          loop &each_tick
        end
        @running = false
        self
      end

      def step(timeout = nil)
        if sel = IO.select(@selectable, [], [], timeout)
          sel[0].each do |readable|
            case readable
            when @control_srv
              client = Client.new self, *@control_srv.accept_nonblock
              @clients[client.control_sock] = client
              @selectable << client.control_sock
            when @notify_srv
              sock, addr = @notify_srv.accept_nonblock
              claim_key = (0...40).map{(65 + rand(25)).chr}.join
              @notify_anon[claim_key] = [sock, addr]
              begin
                @encoder.send_message sock, :claim_key, claim_key
              rescue => e
                puts "ERROR: Failed to send claim key (#{e.inspect})"
              end
            else
              client = @clients[readable]
              begin
                dispatch client, *@encoder.recv_message(readable)
              rescue => e
                puts "[#{client.object_id}] MALFORMED: #{e.inspect}"
                client.respond :error, 'malformed message'
              end
            end
          end
        end
        self
      end

      # only internally mutable
      def clients
        @clients.values
      end

      def notify_all(type, *data)
        @clients.values.each {|c| c.notify type, *data}
      end
      alias_method :broadcast, :notify_all

      private

      def dispatch(client, action, *data)
        begin
          puts "[#{client.object_id}] #{action} => #{data}"
          handler = client.handler || @default_handler
          if handler && handler.respond_to?(m = :"handle_#{action}", true)
            handler.send m, client, *data
          elsif h = @global_handlers[action]
            h.call client, *data
          elsif h = @global_handlers[nil]
            h.call client, action, *data
          else
            client.respond :invalid_action
          end
        rescue => e
          raise e unless @suppress_handler_errors
          puts "  HANDLER: #{e.inspect}"
        end
      end

      def claim_notify(client, key)
        if @notify_anon.has_key?(key)
          client.notify_sock.close if client.notify_sock
          client.notify_sock = @notify_anon.delete(key)[0]
          client.respond :success
        else
          client.respond :invalid_claim_key
        end
      end

    end

  end
end