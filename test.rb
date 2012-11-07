#!/usr/bin/env ruby


require 'bundler/setup'
require 'websocket_handler'




class MesageHandler
  include Celluloid

  def on_message(client,msg)
    puts "#{client} --> #{msg}"
  end

  def on_open(client)
    puts "New connection : #{client}"
  end

  def on_close(client)
    puts "Connection gone  : #{client}"
  end

end


message_actor = MesageHandler.new

handler_actor = WebsocketHandler::Handler.new do |handler|
  handler.addr          = "127.0.0.1"
  handler.port          = 1234
  handler.logger       = STDERR
  handler.manager   = message_actor 
end












sleep
