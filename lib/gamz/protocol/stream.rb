module Gamz
  module Protocol

    class Stream

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
        raise "message is not an array" unless data.kind_of?(Array)
        raise "message contains no data" unless data.length > 0
        raise "first message component is not a string" unless data.first.is_a? String
        @on_message.call self, data if @on_message
      end

    end

  end
end