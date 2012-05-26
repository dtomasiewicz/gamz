module Gamz
  module Protocol

    class Base

      def initialize
        @open = false
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

      def on_message(&block)
        @on_message = block
      end

      # should be extended
      def open(&block)
        on_open &block if block
      end

      # should be extended
      def close(&block)
        on_closed &block if block
      end

      protected

      def open!
        @open = true
        @on_open.call self if @on_open
      end

      def closed!
        @open = false
        @on_closed.call self if @on_closed
      end

      def message!(data)
        @on_message.call self, data if @on_message
      end

    end

  end
end