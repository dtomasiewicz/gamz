require 'json'

module Gamz
  module Protocol

    class JSONSocket < Base

      JSON_ENCODING = 'UTF-8'

      def send_message(id, *data)
        msg = [id]+data
        json = JSON.dump(msg).encode JSON_ENCODING
        len = json.bytesize
        data = [len, json].pack "nA#{len}"
        io.sendmsg_nonblock data
      end

      def recv_message
        len_packed = io.recv_nonblock 2
        raise NoData if len_packed == ""
        json = io.recv_nonblock(len_packed.unpack('n')[0]).force_encoding JSON_ENCODING
        begin
          msg = JSON.parse(json)
        rescue JSON::ParseError
          raise MalformedMessage
        end
        raise MalformedMessage unless msg.kind_of?(Array) && msg.length > 0
        msg[0] = msg[0].to_s
        return *msg
      end

    end

  end
end