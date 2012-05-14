#!/usr/bin/ruby

require 'rubygems'
require 'trollop'
require 'mysql'
require 'yaml'

class Db

  def q( query )

    return @@con.query( query )

  end

  def close()

    @@con.close

  end

  def initialize()

    dbconf_file = "database.yml"

    dbconf = YAML::load(File.open(dbconf_file))

    @@con = Mysql.new( dbconf["host"],
                    dbconf["username"],
                    dbconf["password"],
                    dbconf["database"] )

  end

end

class Domain
  
  attr_accessor :id,
    :domain,
    :domain_obj

  def get_domain_by_id( @id )

    conn = Db.new

    result = Db.q( "SELECT * " +
                 "FROM domain " +
                 "WHERE id = " + @id +
                 "LIMIT 1" )

    conn.close

    return result

  end

  def get_domain_by_name( @domain )

    conn = Db.new

    result = Db.q( "SELECT * " +
                  "FROM domain " +
                  "WHERE domain = '" + @domain + "' " +
                  "LIMIT 1" )

    conn.close

    return result

  end

  def get( search_str )

    if search_str =~ /^\D+$/

      @domain_obj = get_domain_by_id( search_str )

    else

      @domain_obj = get_domain_by_name( search_str )

    end

    return @domain_obj

  end

end

class Address

  attr_accessor :id,
    :local_part,
    :domain_id,
    :user_id,
    :enabled,
    :content_filter,
    :whitelisted_addrs_only

  def initialize( @user_id, address )

    @local_part,domain = address.split("@")



  end

end

class User

  attr_accessor :id, 
    :default_from_addr_id,
    :real_local_addr

  def insert_user_row()

    q = "INSERT INTO users " +
      "( " +
        "real_local_addr " +
      ") " +
      "VALUES " +
      "( " +
        @real_local_addr +
      ") "

    @conn.q( q )

    q = "SELECT LAST_INSERT_ID()"

    return @conn.q( q )

  end

  def save( )

    @conn = Db.new

    @id = insert_user_row

    @default_from_addr_id = Address.new( @id, @real_local_addr )["id"]

    @conn.close

  end

  def initialize( real_local_addr )

    @real_local_addr = real_local_addr

  end

end

class CreateUser
end

class TranslateAddress
end
