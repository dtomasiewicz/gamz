module Gamz

  module Protocol

    class MalformedMessage < IOError
    end

  end

end

require 'gamz/protocol/base'
require 'gamz/protocol/json_socket'
require 'gamz/protocol/json_web_socket'