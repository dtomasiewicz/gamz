module Gamz
  module Client

    class InputStream

      def initialize(input, &block)
        @input, @on_readable = input, block
      end

      def do_read
        @on_readable.call @input if @on_readable
      end

      def to_io
        @input
      end

    end

  end
end