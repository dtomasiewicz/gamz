module Gamz
  module Net

    module Marshal

      # classes in Marshal define two functions that send and receive messages
      # in a non-blocking manner:
      #
      #   send_message(socket, type, *data)
      #     - may raise an exception
      #
      #   recv_message(socket)
      #     - may raise an exception
      #     - returns a tuple of at least 1 element, the first of which is the
      #       message type as a String, and the rest of which are data elements
      #       of any type

    end

  end
end

require 'gamz/net/marshal/json_binary'
require 'gamz/net/marshal/json_base64'