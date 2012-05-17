module Gamz
  module Net

    class Demux

      DEFAULT_TICK_RATE = 60

      attr_accessor :tick_rate

      def initialize
        @tick_rate = DEFAULT_TICK_RATE

        @handlers = {
          read: {},
          write: {},
          error: {}
        }
        @default = {
          read: nil,
          write: nil,
          error: nil
        }

        @timer = []
        @schedule = []

        @running = false
      end

      def read(sock = nil, &block)
        set_handler :read, sock, block
        self
      end

      def stop_read(sock = nil)
        unset_handler :read, sock
        self
      end

      def write(sock = nil, &block)
        set_handler :write, sock, block
        self
      end

      def stop_write(sock = nil)
        unset_handler :write, sock
        self
      end

      def error(sock = nil, &block)
        set_handler :error, sock, block
        self
      end

      def stop_error(sock = nil)
        unset_handler :error, sock
        self
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
        self
      end

      def in(diff, &block)
        at Time.now+diff, &block
      end

      # schedule execution of the passed block to occur in at least <seconds>
      # - the actual time elapsed before execution scales with load (more
      #   load = more skew)
      # - implemented backwards to allow use of pop instead of shift in #start

      def in_scaled(seconds, &block)
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
        raise "demux already running" if @running
        step_timeout = 1.0/@tick_rate

        if timeout
          handle_to = Proc.new do
            if block
              if @running = block.call
                self.in timeout, &handle_to
              end
            else
              @running = false
            end
          end
          self.in timeout, &handle_to
        end

        @running = true
        while @running
          step step_timeout
          @schedule.pop[1].call until @schedule.empty? || @schedule.last[0] > Time.now
          @timer.last[0] -= 1 unless @timer.empty?
          @timer.pop[1].call until @timer.empty? || @timer.last[0] > 0
        end
        self
      end

      def step(timeout = nil)
        if sel = IO.select(@handlers[:read].keys, @handlers[:write].keys, @handlers[:error].keys, timeout)
          sel[0].each {|rsock| invoke_handler :read, rsock}
          sel[1].each {|wsock| invoke_handler :write, wsock}
          sel[2].each {|esock| invoke_handler :error, esock}
        end
        self
      end

      private

      # returns (new) default
      def set_handler(type, sock, handler)
        if sock
          @handlers[type][sock] = handler
        else
          @default[type] = handler
        end
      end

      def unset_handler(type, sock)
        if sock
          @handlers[type].delete sock
        else
          @default[type] = nil
        end
      end

      def invoke_handler(type, sock)
        if h = @handlers[type][sock]
          h.call
        elsif h = @default[type]
          h.call sock
        else
          raise "no suitable handler found for #{sock.inspect}"
        end
      end

    end

  end
end