require 'websocket'
require 'json'

# implements the SERVER side of the WebSocket protocol only!
module Gamz
  module Protocol
    module WebSocket

      class Stream < Protocol::Socket::Stream

        def send_message(msg)
          if open?
            frame = ::WebSocket::Frame::Outgoing::Server.new version: @handshake.version, data: JSON.dump(msg), type: :text
            socket.sendmsg_nonblock frame.to_s
          else
            raise "can't send_message until open"
          end
        end

        def do_read
          begin
            data = socket.recvmsg_nonblock[0]
            raise "clean close" if data.bytesize == 0

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
                  raise "legacy close"
                else
                  raise "unsupported frame type: #{frame.type}"
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
                  socket.close
                end
              end
            else
              raise "data received but WebSocket not active"
            end
          rescue => e
            puts e.inspect
            puts e.backtrace[0]
            socket.close
            closed! if open?
          end
        end

        def ping(data = nil, &block)
          if open?
            @pong_callback = block
            frame = ::WebSocket::Frame::Outgoing::Server.new version: @handshake.version, data: data, type: :ping
            socket.sendmsg_nonblock frame.to_s
          else
            raise "not open"
          end
        end

        def open
          if open?
            raise "already open"
          else
            super
            @handshake = ::WebSocket::Handshake::Server.new
          end
        end

        def close
          if open?
            super
            # TODO only certain protocol versions actually use a close frame... this should
            # check the version first. not sure of the best way to do this.
            frame = ::WebSocket::Frame::Outgoing::Server.new version: @handshake.version, type: :close
            socket.sendmsg_nonblock frame.to_s
            socket.close
            closed!
          else
            raise "not open"
          end
        end

      end

    end
  end
end