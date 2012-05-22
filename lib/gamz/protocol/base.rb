module Gamz
  module Protocol

    class Base

      attr_accessor :io
      alias_method :to_io, :io

      def initialize(io)
        @io = io
        @io_ready = !respond_to?(:initialize_io)
      end

      def io_ready?
        @io_ready
      end

      def on_io_ready(&block)
        if io_ready?
          yield self
        else
          @on_io_ready = block
        end
      end

      def close
        @io.close if @io.respond_to?(:close)
        @io = nil
      end

      protected

      def io_ready!
        @io_ready = true
        @on_io_ready.call self if @on_io_ready
        @on_io_ready = nil
      end

    end

  end
end