
# small fix
module WebSocket
  class Parser
    def process_message!
      case opcode
      when :text
        msg = @current_message.force_encoding("UTF-8")
        raise ParserError.new('Payload data is not valid UTF-8') unless msg.valid_encoding?

        @on_message.call(msg) if @on_message
      when :binary
        @on_message.call(@current_message) if @on_message
      when :ping
        @on_ping.call if @on_ping
      when :pong
        @on_pong.call if @on_ping
      when :close
        status_code, message = @current_message.unpack('S>a*')
        status = STATUS_CODES[status_code]
        @on_close.call(status, message) if @on_close
      end

      # Reset message
      @opcode = nil
      @current_message = nil
    end
  end
end




module WebsocketHandler

  class Connection
    attr_reader :state
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

      @websocket_parser.on_close do |status, reason|
        @socket << ::WebSocket::Message.close.to_data
        raise HandlerError.new(self), "#{status} : #{reason}"
      end 

      read_headers
    end

    def read_headers
      @state = :headers
      begin 
        until @http_parser.headers? 
          @http_parser << @socket.readpartial(BUFFER_SIZE)
        end
      rescue
        @error = $!
      end
      handshake if @error.empty?
    end

    def handshake
      @state = :handshake
      handshake = ::WebSocket::ClientHandshake.new(:get, @http_parser.url, @http_parser.headers)
      if handshake.valid?
        response = handshake.accept_response
        response.render(@socket)
        @state = :attached
      else
        @error = handshake.errors.first
        @socket << "HTTP/1.1 400 #{handshake.errors.first}"
      end
    end

    def listen
      while @state == :attached
        @websocket_parser.append(@socket.readpartial(BUFFER_SIZE)) until message = @websocket_parser.next_message
        @callback[self,message]
      end
    rescue
      raise HandlerError.new(self), $!
    end

    def write(msg)
      @socket << ::WebSocket::Message.new(msg).to_data
      msg
    rescue 
      raise HandlerError.new(self), $!
    end
    alias_method :<<, :write

    def detach
      @socket.close 
      @state = :closed
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

    def error=(err)
      @error = err
    end

    def error
      "error : #{@error}"
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