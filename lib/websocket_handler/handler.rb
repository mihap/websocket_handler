
module WebsocketHandler

  class Handler
    include Celluloid::IO
    @@all = {}


      def self.connections
        @@all
      end


    def initialize(addr, port, logger_name=nil, &callback)
      @addr, @port, @logger = addr, port, logger_name
      @callback = callback
      @logger = Logger.new(logger_name) if logger_name
      @tcp_server = TCPServer.new(@addr,@port)
      run!
    end

    def run
      loop { on_connection! @tcp_server.accept }
    end

    def on_connection(socket)
      conn = Connection.new(socket) do |sender,message|
        @callback[sender,message]
      end

      case conn.state
      when :attached
        @@all[conn.object_id] = conn
        @logger.info "New Connection from #{conn.remote_addr}:#{conn.remote_port}" if @logger
        conn.listen
      else
        @logger.error "#{conn.remote_addr}:#{conn.remote_port}: #{conn.reason}, conn state: #{conn.state}" if @logger
      end

    rescue HandlerError => e
      @logger.error "#{conn.remote_addr}:#{conn.remote_port}: #{conn.reason}" if @logger
      @@all.delete conn.object_id
    end

  end
end