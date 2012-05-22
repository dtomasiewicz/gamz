module Gamz

  module Protocol

    # Protocol instances wrap a raw IO object to handle (un)marshalling of messages
    # Concrete implementations must define #initialize which takes the raw IO object
    # as its first argument, in addition to:
    #
    #   #to_io
    #     - returns the raw IO object (used internally by Kernel.select)
    #
    #   #send_message(id, *data)
    #     - id is a String
    #     - data elements may be of any type supported by the implementation
    #
    #   #recv_message => [id, *data]
    #     - id is a String
    #     - types of data elements depend on implementation
    #     - raises MalformedMessage if the read-in data cannot be unmarshalled
    #     - raises NoData if there is no data available for reading
    #
    # Additionally, protocols that require a handshake routine must define additional
    # methods:
    #
    #   io_ready?
    #     - returns a false value until the handshake is complete, after which
    #       a true value must always be returned
    #
    #   initialize_io
    #     - invoked when the IO object is select'd and io_ready? was false
    #     - implementations that extend Gamz::Protocol::Base will be assumed "ready"
    #       upon construction if they do not define an initialize_io method
    #
    #   on_io_ready(&block)
    #     - a callback to be invoked immediately once the handshake is complete. if
    #       the handshake is already complete when this method is called, the protocol
    #       instance should "yield self" immediately instead of storing the block
    #     - implementations that extend Gamz::Protocol::Base can signal readiness by
    #       calling the protected method io_ready! upon completion of the handshake

    class MalformedMessage < IOError
    end

    class NoData < IOError
    end

  end

end

require 'gamz/protocol/base'
require 'gamz/protocol/json_socket'