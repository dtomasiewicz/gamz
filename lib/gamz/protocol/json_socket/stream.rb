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
          if len_packed == ""
            close
          else
            json = socket.recv_nonblock(len_packed.unpack('n')[0]).force_encoding JSON_ENCODING
            begin
              msg = JSON.parse(json)
              raise unless msg.kind_of?(Array) && msg.length > 0
              msg[0] = msg[0].to_s
            rescue
              msg = nil
            end
            message! msg if msg
          end
        end

        def open
          raise "Cannot re-open a closed socket!" if @closed
          super
          open!
        end

        def close
          super
          @socket.close
          @closed = true
          closed!
        end

      end

    end
  end
end