#!/usr/bin/env ruby
require 'gamz'
require 'json'

class CrazyEights

  def initialize
    @client = Gamz::Net::Client.new
    @client.on_input &method(:handle_input)
    @client.on_notify &method(:handle_notify)
  end

  def start(control_port, notify_port)
    @client.connect control_port, notify_port
    @client.start
    @client.disconnect
  end

  private

  def handle_input(input)
    action, data = input.chomp.split ' ', 2
    data ||= "[]"
    @client.act action, *JSON.parse(data) do |res, *details|
      puts "RES (#{action}) #{res} => #{JSON.dump details}"
    end
  end

  def handle_notify(type, *details)
    puts "NOTIFY #{type} => #{JSON.dump details}"
  end

end

CrazyEights.new.start (ARGV[0] || 10000).to_i, (ARGV[1] || 10001).to_i
