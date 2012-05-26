require 'set'

module Gamz

  class Demux

    DEFAULT_TICK_RATE = 60

    attr_accessor :tick_rate

    def initialize
      @tick_rate = DEFAULT_TICK_RATE

      @streams = {
        read: Set.new,
        write: Set.new,
        error: Set.new
      }

      @timer = []
      @schedule = []

      @running = false
    end

    def add(io, events = [:read])
      events = [events] unless events.respond_to? :each
      events.each do |event|
        @streams[event] << io
      end
      self
    end

    def remove(io, events = [:read, :write, :error])
      events = [events] unless events.respond_to? :each
      events.each do |event|
        @streams[event].delete io
      end
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
      if sel = select(@streams[:read].to_a, @streams[:write].to_a, @streams[:error].to_a, timeout)
        sel[0].each &:do_read
        sel[1].each &:do_write
        sel[2].each &:do_error
      end
      self
    end

  end
  
end