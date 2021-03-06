#!/usr/bin/env ruby
require 'gamz/client'
require 'json'

Class.new do

  def initialize
    @client = Gamz::Client.new
    @client.on_input &method(:handle_input)
    @client.on_notify &method(:handle_notify)
  end

  def start(port)
    @client.open port
    @client.start
    @client.close
  end

  private

  def handle_input(input)
    action, data = input.chomp.split ' ', 2
    begin
      @client.act action, *JSON.parse(data || "[]") do |res, *details|
        puts "RES (#{action}) #{res} => #{JSON.dump details}"
      end
    rescue JSON::ParserError => e
      puts "!!! Could not parse data: #{e.message}"
    end
  end

  def handle_notify(id, *details)
    puts "NOTIFY #{id} => #{JSON.dump details}"
  end

end.new.start (ARGV[0] || 10000).to_i
