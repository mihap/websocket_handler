
module WebsocketHandler

  class Handler
    include Celluloid::IO
    @@all = {}


      def self.connections
        @@all
      end


    def initialize(addr,port,&callback)
      @addr, @port = addr, port
      @callback = callback
      @tcp_server = TCPServer.new(@addr,@port)
      run!
    end

    def run
      # puts " in run actor is #{Actor.current}"
      loop { on_connection! @tcp_server.accept }
    end

    def on_connection(socket)
      connection = Connection.new(socket) do |sender,message|
        @callback[sender,message]
      end

      case connection.state
      when :attached
        @@all[connection.object_id] = connection
        connection.listen
      else
        #TODO Log failed attempt
        puts connection.error
      end

    rescue HandlerError => e
      #TODO log this
      puts $!.inspect

      e.connection.detach
      @@all.delete e.connection.object_id
    end

  end
end