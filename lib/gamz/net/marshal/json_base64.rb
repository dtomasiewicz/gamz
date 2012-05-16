require 'json'
require 'base64'

module Gamz
  module Net
    module Marshal

      class JSONBase64

        attr_reader :json_encoding

        def initialize(json_encoding = 'UTF-8')
          @json_encoding = json_encoding
        end

        def send_message(sock, type, *data)
          msg = {type: type, data: data}
          json = JSON.dump(msg).encode @json_encoding
          b64 = Base64.encode64 json
          sock.sendmsg_nonblock b64
        end

        def recv_message(sock)
          b64 = sock.recvmsg_nonblock[0]
          json = Base64.decode64(b64).force_encoding @json_encoding
          msg = JSON.parse json
          # enforce invariants
          raise "not a hash" unless msg.kind_of?(Hash)
          raise "no String 'type' given" unless msg['type'].kind_of?(String)
          msg['data'] ||= []
          raise "data is not an array" unless msg['data'].kind_of?(Array)
          return [msg['type']]+msg['data']
        end

      end

    end
  end
end