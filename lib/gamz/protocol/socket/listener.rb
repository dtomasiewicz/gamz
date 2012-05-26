require 'socket'

module Gamz
  module Protocol
    module Socket

      class Listener < Protocol::Listener

        def initialize(port, opts = {})
          @port = port
          @host = opts[:host] || '0.0.0.0'
          @backlog = opts[:backlog] || 10
        end

        def to_io
          @socket
        end

        def open
          @socket = ::Socket.new :INET, :STREAM
          @socket.setsockopt ::Socket::SOL_SOCKET, ::Socket::SO_REUSEADDR, true
          @socket.bind ::Socket.sockaddr_in(@port, @host)
          @socket.listen @backlog
        end

        def close
          @socket.close
          @socket = nil
        end

        def do_read
          socket, address = @socket.accept_nonblock
          accept! create_client(socket, address)
        end

        protected

        def create_client(socket, address)
          Client.new Stream.new(socket), address
        end

      end

    end
  end
end