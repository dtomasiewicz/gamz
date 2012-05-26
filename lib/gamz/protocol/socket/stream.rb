require 'json'

module Gamz
  module Protocol
    module Socket

      class Stream < Protocol::Stream

        # abstract :send_message, :do_read

        def initialize(socket)
          super()
          @socket = socket
        end

        def to_io
          @socket
        end

        protected

        attr_reader :socket

      end

    end
  end
end