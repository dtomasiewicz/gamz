module Gamz
  module Net

    class ServiceClient

      attr_accessor :control_sock, :address, :notify_sock, :state_handler

      def initialize(server, control_sock, address)
        @server, @control_sock, @address = server, control_sock, address
        @state_handler = nil
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