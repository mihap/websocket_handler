#!/usr/bin/env ruby


require 'bundler/setup'
require 'websocket_handler'




class MesageHandler
  include Celluloid

  def initialize
    # @websocket_handler = WebsocketHandler::Handler.new "127.0.0.1", "1234",STDERR, Actor.current
  end

  def handle_message(sender,msg)

    puts "#{sender.remote_addr}:#{sender.remote_port} --> #{msg}"
    puts "handling message : #{Thread.current}"
    puts "Your Name:"
    abra = gets
    puts "user input : #{abra}"
    WebsocketHandler::Handler.connections.each do |k,v|
      v.write "#{sender.remote_addr}:#{sender.remote_port} says : #{msg}"
    end
  end

  def on_open(id)
    puts "New connection : #{id}"
  end

  def on_close(id)
    puts "Connection gone  : #{id}"
  end

end


message_actor = MesageHandler.new
handler_actor = WebsocketHandler::Handler.new "127.0.0.1", "1234",STDERR, message_actor










sleep
