#!/usr/bin/env ruby


require 'bundler/setup'
require 'websocket_handler'

def handle_message(msg)
  puts msg
end

WebsocketHandler::Handler.new "127.0.0.1", "1234", &method(:handle_message)






sleep
