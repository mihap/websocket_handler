
# byte order fixed
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

  #check for proper header added
  class ClientHandshake < Http::Request
    def valid?
      if ! headers['Upgrade'] || headers['Upgrade'].downcase != 'websocket'
        errors << 'Connection upgrade is not for websocket'
        return false
      end

      # Careful: Http gem changes header capitalization,
      # so Sec-WebSocket-Version becomes Sec-Websocket-Version
      if headers['Sec-Websocket-Version'].to_i != PROTOCOL_VERSION
        errors << "Protocol version not supported '#{headers['Sec-Websocket-Version']}'"
        return false
      end

      return true
    end
  end

end