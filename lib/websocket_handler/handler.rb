
module WebsocketHandler

  class Handler
    include Celluloid::IO

    attr_accessor :logger

    def initialize(addr,port,&callback)
      @addr, @port = addr, port
      @callback = callback
      @tcp_server = TCPServer.new(@addr,@port)
      run!
    end

    def run
      loop { on_connection! @tcp_server.accept }
    end

    def on_connection(socket)
      connection = Connection.new(socket) do |message|
        @callback[message]
      end
    end



  end
end