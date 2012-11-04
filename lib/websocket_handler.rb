
require 'celluloid/io'

require "websocket_parser"
require "websocket_handler/handler.rb"
require "websocket_handler/connection.rb"
require "websocket_handler/version.rb"

module WebsocketHandler
  class HandlerError < StandardError;
    attr_reader :connection 
    def initialize(connection)
      @connection = connection
    end
  end
end