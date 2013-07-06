require 'json'

module Gamz
  module Protocol
    module JSONSocket

      class Stream < Protocol::Socket::Stream

        JSON_ENCODING = 'UTF-8'

        def send_message(msg)
          json = JSON.dump(msg).encode JSON_ENCODING
          len = json.bytesize
          data = [len, json].pack "nA#{len}"
          socket.sendmsg_nonblock data
        end

        def do_read
          len_packed = socket.recv_nonblock 2
          return close if len_packed.bytesize == 0

          json = socket.recv_nonblock(len_packed.unpack('n')[0]).force_encoding JSON_ENCODING
          message! JSON.parse(json)
        end

        def open
          raise IOError, "Cannot re-open a closed socket!" if @closed
          super
          open!
        end

        def close
          raise IOError, "already closed" if @closed

          super

          begin
            socket.close
          rescue IOError => e
            puts e.inspect
            puts e.backtrace[0]
          end
          
          @closed = true
          closed!
        end

      end

    end
  end
end