
module WebsocketHandler

  class Connection
    attr_reader :state, :reason
    BUFFER_SIZE = 4096

    def initialize(socket,&callback)
      @socket = socket
      @callback = callback
      @reason = ""

      @http_parser = HttpParser.new
      @websocket_parser = ::WebSocket::Parser.new
      
      @websocket_parser.on_ping do
        @socket << ::WebSocket::Message.pong.to_data
      end

      @websocket_parser.on_close do |s, r|
        @socket << ::WebSocket::Message.close.to_data
        @reason = "#{s} : #{r}"
        raise HandlerError
        # detach
      end 

      read_headers
    end
    


    def read_headers
      @state = :headers
      begin 
        until @http_parser.headers? 
          @http_parser << @socket.readpartial(BUFFER_SIZE)
        end
        puts @http_parser.headers
      rescue
        @reason = $!.message
      end
      handshake if @reason.empty?
    end

    def handshake
      @state = :handshake
      handshake = ::WebSocket::ClientHandshake.new(:get, @http_parser.url, @http_parser.headers)
      puts handshake.class
      if handshake.valid?
        response = handshake.accept_response
        response.render(@socket)
        @state = :attached
      else
        @reason = handshake.errors.first
        @socket << "HTTP/1.1 400 #{handshake.errors.first}"
      end
    end

    def listen
      while @state == :attached
        @websocket_parser.append(@socket.readpartial(BUFFER_SIZE)) until message = @websocket_parser.next_message
        @callback[self,message]
      end
    rescue
      if @state == :attached
        @reason = $!.message
        raise HandlerError
        detach 
      end
    end

    def write(msg)
      @socket << ::WebSocket::Message.new(msg).to_data
      msg
    rescue 
      # @reason = $!.message
      raise HandlerError
    end
    alias_method :<<, :write

    def detach
      @state = :closed
      @socket.close 
    end

    def remote_addr
      @socket.peeraddr(false)[3]
    end

    def remote_port
      @socket.peeraddr(false)[1]
    end

    def remote_host
      @socket.peeraddr(true)[2]
    end

  end

  class HttpParser
    attr_reader :headers

    def initialize
      @parser = Http::Parser.new(self)
      reset
    end

    def add(data)
      @parser << data
    end
    alias_method :<<, :add

    def url
      @parser.request_url
    end

    def headers?
      !!@headers
    end
    
    def on_headers_complete(headers)
      @headers = headers
      @finished = true
    end

    def reset
      @finished = false
      @headers  = nil
    end
  end

end