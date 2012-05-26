require 'socket'

module Gamz
  module Listener

    class Socket

      def initialize(port, opts = {})
        @port = port
        @host = opts[:host] || '0.0.0.0'
        @protocol = opts[:protocol] || Gamz::Protocol::JSONSocket
        @backlog = opts[:backlog] || 10
      end

      def on_accept(&block)
        @on_accept = block
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
        @on_accept.call @protocol.new(socket), address if @on_accept
      end

    end

  end
end