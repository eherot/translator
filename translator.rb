#!/usr/bin/ruby

require 'rubygems'
require 'trollop'
require 'mysql'
require 'yaml'

class Db

  def q( query )

    result = @@con.query( query )
    
    r_hash = result.fetch_hash

    result.free

    return r_hash

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

  def update_existing( )
    
    # TODO
    #
    raise "Not Implemented."

  end

  def insert_addr( )

    q = "INSERT INTO addresses " +
      "( " +
        "local_part, " +
        "domain_id, " +
        "user_id, " +
        "enabled, "

    if @content_filter

      q += "content_filter, "

    end

    q += "whitelisted_addrs_only " +
      ") VALUES ( " +
        "'" + @local_part + "', " +
        @domain_id + ", " +
        @user_id + ", "

    if @enabled

      q+= @enabled + ", "

    end

    if @content_filter

      q += @content_filter + ", "

    end

    if @whitelisted_addrs_only
      
      q += @whitelisted_addrs_only + ", "

    end

    q += " )"
    
    @conn.q( q )

    q = "SELECT LAST_INSERT_ID()"

    return @conn.q ( q )

  end

  def save()

    if @id

      update_existing( )

    else

      @id = insert_addr( )

    end

  end

  def initialize( @user_id, address )

    @local_part,domain = address.split("@")

    @domain_id = Domain.get( domain )
    
    if ! @domain_id

      raise "Address contains invalid domain"

    end

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

    addr = Address.new( @id, @real_local_addr )
    addr.save
    
    @default_from_addr_id = addr.id

    @conn.close

  end

  def initialize( real_local_addr )

    @real_local_addr = real_local_addr

  end

end

class Translator

  def process_opts()

    opts = Trollop::options do
      opt :createuser, "Register a new user", :short => "n", :type => :string
      opt :from, "From Address", :short => "f", :type => :string
      opt :to, "To Address", :short => "t", :type => :string
      opt :direction, "Direction: inbound/outbound", :short => "d", :type => :string
      opt :createalias, "Create an alias adddress (requires -u)", :short => "a", :type => :string
      opt :user, "Real local address associated with alias", :short => "u", :type => :string
    end

    return opts

  end

  def translate_address( from, to, direction )

    case direction
    when "inbound"

    when "outbound"
    end

  end

  def create_alias( alias_addr, real_local_addr )

    u_id = User.get( real_local_addr ).id

    a = Alias.new( u_id, alias_addr )

    a.save

    puts "Alias created.  ID: #{a.id}"

  end

  def create_user( real_local_addr )

    # In our system, real_local_addr and "username" are essentially
    # interchangeable concepts. ;-)
    
    u = User.new( real_local_addr )
    u.save

    puts "User created.  ID: #{u.id}"

  end

  def initialize()

    opts = process_opts

    case
      when opts[:from] && opts[:to] && opts[:direction]
    
        output = translate_address( opts[:from], 
                                      opts[:to], 
                                      opts[:direction] )

        if opts[:direction] == "inbound"

          real_local_address = output

          puts real_local_address
          
        end

      when opts[:createuser]

        create_user( opts[:createuser] )

      when opts[:createalias] && opts[:user]

        create_alias( opts[:createalias], opts[:user] )

    end

  end

end

Translator.new()
