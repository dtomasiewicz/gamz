module Gamz
  module Server

    class Client

      attr_accessor :control_sock, :address, :notify_sock, :reactor

      def initialize(service, control_sock, address)
        @service, @control_sock, @address = service, control_sock, address
        @reactor = nil
      end

      def notify(*args)
        begin
          @service.encoder.send_message @notify_sock, *args if @notify_sock
        rescue => e
          puts "[#{object_id}] NOTIFY: #{e.inspect}"
        end
      end

    end

  end
end