#!/usr/bin/env ruby
require 'socket'
require 'gamz'
require 'json'

class CrazyEights

  TICK = 1.0/2

  def initialize
    @encoder = Gamz::Net::Marshal::JSONBase64.new
  end

  def start(control_port, notify_port)
    @control = Socket.new :INET, :STREAM
    @control.connect Addrinfo.tcp('127.0.0.1', control_port)

    @notify = Socket.new :INET, :STREAM
    @notify.connect Addrinfo.tcp('127.0.0.1', notify_port)

    read_socks = [@control, @notify, STDIN]
    puts "> "

    shutdown = false
    until shutdown
      if sel = IO.select(read_socks, [], [], 0)
        sel[0].each do |readable|
          case readable
          when @control
            type, data = @encoder.recv_message @control
            puts "CONTROL: #{type} => #{data}"
            case type
            when :close
              shutdown = true
            end
          when @notify
            type, data = @encoder.recv_message @notify
            puts "NOTIFY: #{type} => #{data}"
            case type
            when :claim_key
              # TODO
            end
          when STDIN
            type, data = STDIN.gets.chomp.split ' ', 2
            data ||= "[]"
            @encoder.send_message @control, type, *JSON.parse(data)
          end
        end
        puts "> "
      end
      sleep TICK
    end

    @control.close
    @notify.close
  end

end

CrazyEights.new.start (ARGV[0] || 10000).to_i, (ARGV[1] || 10001).to_i
