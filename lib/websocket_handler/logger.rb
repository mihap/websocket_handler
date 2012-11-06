
module WebsocketHandler
  
  class Logger
    
    def initialize(name)
      case name
      when IO, String
        @logger = ::Logger.new(name, shift_age = 7, shift_size = 1048576)
      else
        raise "logger should be IO or filename"
      end
    end

    def logger
      @logger
    end
    
    def debug(msg); @logger.debug(msg); end
    def info(msg);  @logger.info(msg);  end
    def warn(msg);  @logger.warn(msg);  end
    def error(msg); @logger.error(msg); end

  end
end