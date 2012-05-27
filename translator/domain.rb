require "translator/db"

class Domain
  
  attr_accessor :id,
    :domain

  def self.get_domain_by_id( id )

    conn = Db.new

    result = conn.q( "SELECT * " +
                 "FROM domains " +
                 "WHERE id = " + id +
                 " LIMIT 1" )

    conn.close

    return result

  end

  def self.get_domain_by_name( name )

    conn = Db.new

    result = conn.q( "SELECT * " +
                  "FROM domains " +
                  "WHERE domain = '" + name + "' " +
                  "LIMIT 1" )

    conn.close

    return result

  end

  def self.get( search_str )

    if search_str =~ /^\D+$/

      domain_obj = get_domain_by_name( search_str )

    else

      domain_obj = get_domain_by_id( search_str )

    end

    return domain_obj

  end

end
