module Gamz
  module Protocol

    class Base

      attr_accessor :io
      alias_method :to_io, :io

      def initialize(io, &block)
        @io = io
        @open = false

        open! &block if block
      end

      def open?
        @open
      end

      def on_open(&block)
        @on_open = block
      end

      def on_closed(&block)
        @on_closed = block
      end

      # should be extended
      def open!(&block)
        on_open &block if block
      end

      # should be extended
      def close!(&block)
        on_closed &block if block
      end

      protected

      def now_open!
        @open = true
        @on_open.call self if @on_open
      end

      def now_closed!
        @open = false
        @on_closed.call self if @on_closed
      end

    end

  end
end