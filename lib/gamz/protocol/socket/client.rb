module Gamz
  module Protocol
    module Socket

      class Client < Protocol::Client

        attr_reader :address

        def initialize(stream, address)
          super(stream)
          @address = address
        end

        def to_s
          "#{super}@#{@address.ip_address}:#{@address.ip_port}"
        end

      end

    end
  end
end