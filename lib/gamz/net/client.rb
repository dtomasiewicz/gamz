module Gamz
  module Net

    class Client

      attr_accessor :control_sock, :address, :notify_sock, :handler

      def initialize(server, control_sock, address)
        @server, @control_sock, @address = server, control_sock, address
        @handler = nil
      end

      def respond(*args)
        begin
          @server.encoder.send_message @control_sock, *args if @control_sock
        rescue => e
          puts "[#{object_id}] RESPOND: #{e.inspect}"
        end
      end

      def notify(*args)
        begin
          @server.encoder.send_message @notify_sock, *args if @notify_sock
        rescue => e
          puts "[#{object_id}] NOTIFY: #{e.inspect}"
        end
      end

    end

  end 
end