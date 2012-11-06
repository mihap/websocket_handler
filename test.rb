#!/usr/bin/env ruby


require 'bundler/setup'
require 'websocket_handler'

def handle_message(sender,msg)
  puts "#{sender.remote_addr}:#{sender.remote_port} --> #{msg}"
  WebsocketHandler::Handler.connections.each do |k,v|
    v.write "#{sender.remote_addr}:#{sender.remote_port} says : #{msg}"
  end
end

WebsocketHandler::Handler.new "127.0.0.1", "1234",STDERR, &method(:handle_message)






sleep
