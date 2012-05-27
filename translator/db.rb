class Db

  def q( query )

    begin

      result = @con.query( query )
    
      r_hash = result.fetch_hash

    rescue Exception => e

      puts "Original query was: <#{query}>"
      raise

    end

    result.free

    return r_hash

  end

  def close()

    @con.close

  end

  def initialize()

    dbconf_file = "database.yml"

    dbconf = YAML::load(File.open(dbconf_file))

    @con = Mysql.new( dbconf["host"],
                    dbconf["username"],
                    dbconf["password"],
                    dbconf["database"] )

  end

end
