
module WebsocketHandler

  class Handler
    include Celluloid::IO

    def initialize(&config)
      config.call(self)
      @tcp_server = TCPServer.new(@addr,@port)
      run!
     end

     def logger=(logger)
        @logger = Logger.new(logger) 
     end

     def addr=(addr)
      @addr = addr
     end

     def port=(port)
      @port = port
    end

    def manager=(manager)
      @manager = manager
    end

    def run
      loop { on_connection! @tcp_server.accept }
    end

    def on_connection(socket)
      conn = Connection.new(socket) do |message|
        @manager.on_message(conn,message)
     end

      case conn.state
      when :websocket
        @manager.on_open(conn)
        @logger.info "New Connection: #{conn}" if @logger
        conn.listen
      else
        @logger.error "Failed: #{conn}: #{conn.error}, conn state: #{conn.state}" if @logger
      end

    rescue HandlerError
      @manager.on_close(conn)
      @logger.error "#{conn}: #{conn.error}" if @logger
    ensure 
      conn.close
     end
  end
end