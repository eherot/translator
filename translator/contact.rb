require "translator/db"

class Contact

  attr_accessor :contact_email,
    :address_id,
    :whitelisted,
    :blacklisted,
    :conn

  def self.get_by_address( user_id, contact_email )

    q = "SELECT * " +
      "FROM contacts " +
      "WHERE " +
        "user_id = " + user_id +
          " AND " +
        "contact_email = '" + contact_email + "'" +
        " LIMIT 1"

    conn = Db.new

    contact_obj = conn.q( q )

    conn.close

    return contact_obj

  end

  def save

    q = "INSERT INTO contacts " +
      "(" +
        "contact_email," +
        "address_id"

    if @whitelisted

      q += ",whitelisted"

    end

    if @blacklisted

      q += ",blacklisted"

    end

    q += ") VALUES (" +
      "'" + @contact_email + "'," +
      @address_id

    if @whitelisted

      q += "," + @whitelisted.to_s

    end

    if @blacklisted

      q += "," + @blacklisted.to_s

    end

    q += ")"

    @conn.q( q )

    q = "SELECT LAST_INSERT_ID()"

    result = @conn.q( q )["LAST_INSERT_ID()"]

    return result

  end

end
