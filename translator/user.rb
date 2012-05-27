require "translator/db"
require "translator/address"

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

  def self.get_user_by_id( id )

    q = "SELECT * " +
      "FROM users " +
      "WHERE id = " + id +
      " LIMIT 1"

    conn = Db.new

    user_obj = conn.q( q )

    conn.close

    return user_obj

  end

  def self.get_user_by_name( name )
  end

  def self.get( search_str )

    if search_str =~ /^\D+$/

      user_obj = get_user_by_id( search_str )

    else

      user_obj = get_user_by_name( search_str )

    end

    return user_obj

  end

  def save( )

    conn = Db.new

    @id = insert_user_row

    addr = Address.new( @id, @real_local_addr )
    addr.save
    
    @default_from_addr_id = addr.id

    conn.close

  end

  def initialize( real_local_addr )

    @real_local_addr = real_local_addr

  end

end
