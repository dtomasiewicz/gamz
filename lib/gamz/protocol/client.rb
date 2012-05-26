module Gamz
  module Protocol

    class Client

      attr_reader :stream
      attr_accessor :reactor

      def initialize(stream)
        @stream = stream
        @reactor = nil
      end

      def respond(id, *data)
        @stream.send_message ['r_'+id.to_s, *data]
        self
      end

      def notify(id, *data)
        @stream.send_message ['n_'+id.to_s, *data]
        self
      end

      def to_s
        object_id.to_s
      end

    end
  end
end