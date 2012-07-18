require 'json'

module Gamz
  module Protocol
    module Socket

      class Stream < Protocol::Stream

        # abstract :send_message, :do_read

        attr_reader :socket
        alias_method :to_io, :socket

        def initialize(socket)
          super()
          @socket = socket
        end

      end

    end
  end
end