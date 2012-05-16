module Gamz

  class RuleViolation < StandardError

    attr_reader :type

  	def initialize(type, msg = nil)
      @type = type
      super(msg)
  	end

    def to_s
      "#{@type}#{": "+message if message}"
    end

  end

end