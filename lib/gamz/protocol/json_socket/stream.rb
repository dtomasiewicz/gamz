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
          begin
            len_packed = socket.recv_nonblock 2
            raise if len_packed.bytesize == 0
            json = socket.recv_nonblock(len_packed.unpack('n')[0]).force_encoding JSON_ENCODING
            message! JSON.parse(json)
          rescue
            close
          end
        end

        def open
          raise "Cannot re-open a closed socket!" if @closed
          super
          open!
        end

        def close
          super
          socket.close
          @closed = true
          closed!
        end

      end

    end
  end
end