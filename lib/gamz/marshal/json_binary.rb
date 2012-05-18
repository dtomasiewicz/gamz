require 'json'

module Gamz
  module Marshal

    class JSONBinary

      attr_reader :json_encoding

      def initialize(json_encoding = 'UTF-8')
        @json_encoding = json_encoding
      end

      def send_message(sock, type, *data)
        msg = {type: type, data: data}
        json = JSON.dump(msg).encode @json_encoding
        len = json.bytesize
        data = [len, json].pack("nA#{len}")
        sock.sendmsg_nonblock data
      end

      def recv_message(sock)
        len_packed = sock.recv_nonblock 2
        raise SocketClosed if len_packed == ""
        json = sock.recv_nonblock(len_packed.unpack('n')[0]).force_encoding @json_encoding
        msg = JSON.parse json
        # enforce invariants
        raise MalformedMessage unless msg.kind_of?(Hash)
        msg['data'] ||= []
        raise MalformedMessage unless msg['type'].kind_of?(String) && msg['data'].kind_of?(Array)
        return [msg['type']]+msg['data']
      end

    end

  end
end