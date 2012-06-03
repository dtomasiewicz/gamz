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

    # schedule execution of the passed block at the given _time_ (or as soon
    # afterwards as possible)
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

    # schedule execution of the passed block in _seconds_ seconds
    def seconds(seconds, &block)
      at Time.now+seconds, &block
      self
    end

    # schedule execution of the passed block after _ticks_ ticks
    def ticks(ticks, &block)
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

    # Calls the given _block_ every _period_ seconds. If _immediate_ is true
    # (default), the first execution will occur immediately. If _preemptive_ is
    # true (default), the next execution will be scheduled *before* the current 
    # one, resulting in uniform delays between block calls regardless of the
    # block's execution time.
    def each_seconds(period, immediate = true, preemptive = true, &block)
      if preemptive
        cycle = proc { self.seconds period, &cycle; block.call }
      else
        cycle = proc { block.call; self.seconds period, &cycle }
      end
      if immediate
        cycle.call
      else
        self.seconds period, &cycle
      end
      self
    end

    # Calls the given _block_ every _period_ ticks. If _immediate_ is true
    # (default), the firs texecution will occur immediately.
    def each_ticks(delta, immediate = true, &block)
      cycle = proc { block.call; self.ticks ticks, &cycle }
      if immediate
        cycle.call
      else
        self.ticks ticks, &cycle
      end
      self
    end

    # Start the demultiplexer's main loop. If _timeout_ is given without a
    # block, will run for at least that many seconds before this method 
    # returns.
    #
    # If _timeout_ is given along with a block, will run for at least _timeout_
    # seconds, then execute the block and run for _timeout_ seconds again if
    # the block returns a true value, repeating until the block returns a false
    # value.
    #
    # If no _timeout_ is given, the server will run until interrupted.
    def start(timeout = nil, &block)
      raise "demux already running" if @running
      step_timeout = 1.0/@tick_rate

      if timeout
        cycle = proc do
          if block
            if @running = block.call
              self.in timeout, &cycle
            end
          else
            @running = false
          end
        end
        self.in timeout, &cycle
      end

      @running = true
      while @running
        @schedule.pop[1].call until @schedule.empty? || @schedule.last[0] > Time.now
        @timer.pop[1].call until @timer.empty? || @timer.last[0] > 0
        step step_timeout
        @timer.last[0] -= 1 unless @timer.empty?
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