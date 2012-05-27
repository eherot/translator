require "translator/db"
require "translator/domain"

class Address

  attr_accessor :id,
    :local_part,
    :domain_id,
    :user_id,
    :enabled,
    :content_filter,
    :whitelisted_addrs_only

  def self.update_existing( )
    
    # TODO
    #
    raise "Not Implemented."

  end

  def self.get_addr_by_id( id )

    conn = Db.new

    result = Db.q( "SELECT * " +
                 "FROM addresses " +
                 "WHERE id = " + id +
                 "LIMIT 1" )

    conn.close

    return result

  end

  def self.get_addr_by_name( name )

    conn = Db.new

    domain_name = name.split("@").last

    domain_id = Domain.get( domain_name )["id"]

    result = Db.q( "SELECT * " +
                 "FROM addresses " +
                 "WHERE " +
                   "local_part = '" + local_part + "'" +
                     " AND " +
                   "domain_id = " + domain_id + 
                 " LIMIT 1" )

    conn.close

    return result

  end

  def self.get( search_str )

    if search_str =~ /^\D+$/

      addr_obj = get_addr_by_name( search_str )

    else

      addr_obj = get_addr_by_id( search_str )

    end

    return addr_obj

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
        @user_id

    if @enabled

      q+= "," + @enabled

    end

    if @content_filter

      q += "," + @content_filter

    end

    if @whitelisted_addrs_only
      
      q += "," + @whitelisted_addrs_only

    end

    q += " )"
    
    @conn.q( q )

    q = "SELECT LAST_INSERT_ID()"

    return @conn.q( q )["LAST_INSERT_ID()"]

  end

  def self.generate_uniq_addr( user_obj )

    default_from_addr_obj = Address.get( user_obj["default_from_addr_id"] )

    domain_name = Domain.get( default_from_addr_obj["domain_id"] )["domain"]

    new_uniq_addr = default_from_addr_obj["local_part"] + "." + 
      String.random(5) + "@" + domain_name

    while Address.get( new_uniq_addr )

      # In the event that this address combo was already used, choose a new one

      new_uniq_addr = default_from_addr_obj["local_part"] + "." + 
        String.random(5) + "@" + domain_name

    end

    return new_uniq_addr

  end

  def save()

    if @id

      update_existing( )

    else

      @id = insert_addr( )

    end

  end

  def initialize( user_id, address )

    @user_id = user_id

    @local_part,domain = address.split("@")

    @domain_id = Domain.get( domain )
    
    if ! @domain_id

      raise "Address contains invalid domain"

    end

  end

end
