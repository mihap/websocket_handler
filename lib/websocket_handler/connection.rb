
module WebsocketHandler

  class Connection
    
    BUFFER_SIZE = 4096

    def initialize(socket,&callback)
      @socket = socket
      @parser = HttpParser.new
      @callback = callback

      until @parser.headers? 
        @parser << socket.readpartial(BUFFER_SIZE)
      end

      handshake = ::WebSocket::ClientHandshake.new(:get, @parser.url, @parser.headers)
      if handshake.valid?
        response = handshake.accept_response
        response.render(@socket)
        listen(@socket)
      end
    
    end

    def listen(socket)
      parser = ::WebSocket::Parser.new
      loop do
        parser.append(socket.readpartial(4096)) until message = parser.next_message
        @callback[message]
      end
    rescue 
      puts $!
    end



    def remote_addr
      @socket.peeraddr(false)[3]
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