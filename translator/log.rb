class Log

  def self.log_out( level, msg )

    puts "#{level}: #{msg}"

  end

  def self.info( msg )

    log_out( "info", msg )

  end

  def self.debug( msg )

    if $DEBUG

      log_out( "debug", msg )

    end

  end

  def self.error( msg )

    log_out( "error", msg )

  end

end
