require 'websocket'
require 'json'

# implements the SERVER side of the WebSocket protocol only!
module Gamz
  module Protocol
    module WebSocket

      class Stream < Protocol::Socket::Stream

        def send_message(msg)
          raise ::WebSocket::Error, "can't send_message until open" unless open?

          frame = ::WebSocket::Frame::Outgoing::Server.new version: @handshake.version, data: JSON.dump(msg), type: :text
          socket.sendmsg_nonblock frame.to_s
        end

        def do_read
          data = socket.recvmsg_nonblock[0]
          return underlying_close if data.bytesize == 0

          if open?
            @frame << data
            while frame = @frame.next
              case frame.type
              when :text
                message! JSON.parse(frame.to_s)
              when :ping
                pong = ::WebSocket::Frame::Outgoing::Server.new version: @handshake.version, data: frame.data, type: :pong
                socket.sendmsg_nonblock pong.to_s
              when :pong
                if handler = @pong_callback
                  @pong_callback = nil
                  handler.call frame.data
                end
              when :close
                underlying_close
              else
                raise ::WebSocket::Error::Frame::UnknownFrameType, frame.type.to_s
              end
            end
          elsif !@handshake.finished?
            @handshake << data
            if @handshake.finished?
              socket.sendmsg_nonblock @handshake.to_s
              if @handshake.valid?
                @frame = ::WebSocket::Frame::Incoming::Server.new version: @handshake.version
                open!
              else
                raise ::WebSocket::Error::Handshake, "invalid"
              end
            end
          else
            raise ::WebSocket::Error, "data received but WebSocket not open"
          end
        end

        def ping(data = nil, &block)
          raise ::WebSocket::Error, "can't ping until open" unless open?

          @pong_callback = block
          frame = ::WebSocket::Frame::Outgoing::Server.new version: @handshake.version, data: data, type: :ping
          if frame.support_type?
            socket.sendmsg_nonblock frame.to_s
          else
            raise ::WebSocket::Error, "protocol version does not support ping"
          end
        end

        def open
          raise ::WebSocket::Error, "already open" if open?

          super
          @handshake = ::WebSocket::Handshake::Server.new
        end

        def close
          raise ::WebSocket::Error, "not open" unless open?

          super

          frame = ::WebSocket::Frame::Outgoing::Server.new version: @handshake.version, type: :close
          begin
            socket.sendmsg_nonblock frame.to_s
          rescue Errno::ECONNRESET => e
            puts e.inspect
            puts e.backtrace[0]
          end if frame.support_type?

          underlying_close
        end

        private

        def underlying_close
          begin
            socket.close
          rescue IOError => e
            puts e.inspect
            puts e.backtrace[0]
          end

          closed!
        end

      end

    end
  end
end