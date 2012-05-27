class Db

  def q( query )

    r_hash = {}

    begin

      result = @con.query( query )
    
      if result
        
        r_hash = result.fetch_hash

        result.free

      end

    rescue Exception => e

      puts "Original query was: <#{query}>"
      raise

    end

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
