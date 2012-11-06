
require 'celluloid/io'

require "websocket_parser"
require "logger"
require "websocket_handler/logger.rb"
require "websocket_handler/handler.rb"
require "websocket_handler/connection.rb"
require "websocket_handler/version.rb"

module WebsocketHandler
  class HandlerError < StandardError; end;
end