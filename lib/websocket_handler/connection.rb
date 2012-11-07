
module WebsocketHandler

  class Connection
    attr_reader :state, :error
    BUFFER_SIZE = 4096

    def initialize(socket,&callback)
      @socket = socket
      @callback = callback
      @error = ""

      @http_parser = HttpParser.new
      @websocket_parser = ::WebSocket::Parser.new
      
      @websocket_parser.on_ping do
        @socket << ::WebSocket::Message.pong.to_data
      end

      @websocket_parser.on_close do |s, r|
        @socket << ::WebSocket::Message.close.to_data
        @state = :closing
        @error = "#{s}:#{r}"
        raise HandlerError
      end 

      read_headers
    end

    def read_headers
      @state = :headers
      @http_parser << @socket.readpartial(BUFFER_SIZE) until  @http_parser.headers? 
      rescue
        @error = $!.message
      ensure
        handshake if @error.empty?
    end

    def handshake
      @state = :handshake
      handshake = ::WebSocket::ClientHandshake.new(:get, @http_parser.url, @http_parser.headers)
      if handshake.valid?
        response = handshake.accept_response
        response.render(@socket)
        @state = :websocket
      else
        @error = handshake.errors.first
        @socket << "HTTP/1.1 400 #{handshake.errors.first}"
      end
    end

    def listen
      loop do
        @websocket_parser.append(@socket.readpartial(BUFFER_SIZE)) until message = @websocket_parser.next_message
        @callback[message]
      end
    rescue IOError
      unless closing?
        @error = $!.message
        raise HandlerError
      end
    end

    def write(msg)
      @socket << ::WebSocket::Message.new(msg).to_data
      msg
    rescue IOError
      @error = $!.message
      raise HandlerError
    end
    alias_method :<<, :write

    def close
      @state = :closed
      @socket.close 
    end

    def closing?
      @state == :closing
    end

    def to_s
      "#{remote_addr}:#{remote_port}"
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