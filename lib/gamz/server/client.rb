module Gamz
  module Server

    class Client

      attr_accessor :stream, :address, :reactor

      def initialize(stream, address)
        @stream, @address = stream, address
        @reactor = nil
      end

      def respond(id, *data)
        @stream.send_message 'r_'+id.to_s, *data if @stream
        self
      end

      def notify(id, *data)
        @stream.send_message "n_"+id.to_s, *data if @stream
        self
      end

    end

  end
end