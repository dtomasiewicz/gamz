module Gamz
  module Protocol

    class JSONWebSocket < Base

      def on_readable
        if @opening
          opening_handshake
          return nil
        elsif @closing
          closing_handshake
          return nil
        else
          # ping? pong? message?
        end
      end

      def close!
        @closing = true
        # send closing message
      end

      private

      def opening_handshake
      end

      def closing_handshake
      end

    end

  end
end