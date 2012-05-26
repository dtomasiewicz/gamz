module Gamz
  module Protocol

    class Listener

      def on_accept(&block)
        @on_accept = block
      end

      protected

      def accept!(client)
        @on_accept.call client if @on_accept
      end

    end

  end
end