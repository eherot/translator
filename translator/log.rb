class Log

  def self.log_out( level, msg )

    puts "#{level}: #{msg}"

  end

  def self.error( msg )

    log_out( "error", msg )

  end

end
