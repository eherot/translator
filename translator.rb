#!/usr/bin/ruby

require 'rubygems'
require 'trollop'
require 'mysql'
require 'yaml'

require 'translator/log'
require 'translator/address'
require 'translator/contact'
require 'translator/user'

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

    # On "inbound" this method should return the "real" local address where
    # the mail is supposed to go.
    #
    # On "outbound" it should return the "fake" FROM address where the mail
    # should appear to come from.

    case direction
    when "inbound"

      if a_obj = Address.get( to )

        u_id = a_obj["user_id"]

        real_local_addr = User.get( u_id )["real_local_addr"]

        return real_local_addr

      else

        recipient_local_part,recipient_domain = to.split("@")

        recipient_local_part_arr = recipient_local_part.split(".")

        real_addr_part = recipient_local_part_arr[0..-2].join(".")

        unique_addr_part = recipient_local_part_arr.last

        real_local_addr = real_addr_part + "@" + recipient_domain

        if a_obj = Address.get( real_local_addr )

          db_conn = Db.new

          user_id = a_obj["user_id"]

          a = Address.new( user_id, to )

          a.conn = db_conn

          a.save

          c = Contact.new

          c.conn = db_conn
          
          c.user_id = user_id
          c.contact_email = from
          c.address_id = a.id
          c.whitelisted,c.blacklisted = 0,0

          c.save

          db_conn.close

          return real_local_addr

        else

          Log.error "INVALID RECIPIENT ADDRESS"
          exit 1

        end

      end

    when "outbound"

      if u_id = Address.get( from )["user_id"]

        if c_obj = Contact.get_by_address( u_id, to )

          Log.info( "OUTBOUND: EXISTING CONTACT (UID: #{u_id})" )

          # User has had previous contact with this outside contact.
          # Lets find out what is their associated address so we can
          # use it in the "FROM" field.

          new_from_addr_obj = Address.get( c_obj["address_id"] )

          new_from_local_part = new_from_addr_obj["local_part"]

          new_from_domain = Domain.get( new_from_addr_obj["domain_id"] )["domain"]

          new_from_addr = new_from_local_part + "@" + new_from_domain

        else

          # User has not previously sent or received anything from this
          # outside contact.  We must add a new contacts entry for this 
          # contact and either create a new unique address or associate
          # the contact with the user's primary address (depending on
          # configuration).

          Log.info( "OUTBOUND: NEW CONTACT (UID: #{u_id})" )

          contact = Contact.new

          contact.contact_email = to
          contact.user_id = u_id

          u_obj = User.get( u_id )

          if u_obj["new_addr_on_outbound"] == 1

            Log.debug( "new_addr_on_outbound ENABLED" )

            new_unique_address = Address.generate_uniq_addr( u_obj )

            addr = Address.new( u_id, new_unique_address )
            addr.save

            contact.address_id = addr.id

            new_from_addr = new_unique_address

          else

            Log.debug( "new_addr_on_outbound DISABLED" )

            contact.address_id = u_obj["default_from_addr_id"]

            new_from_addr_obj = Address.get( u_obj["default_from_addr_id"] )
            new_from_addr_domain_obj = Domain.get( new_from_addr_obj["domain_id"] )

            new_from_addr = new_from_addr_obj["local_part"] + 
              new_from_addr_domain_obj["domain"]

          end

          contact.whitelisted = 1
          contact.blacklisted = 0

          contact.conn = Db.new

          contact.save

          contact.conn.close

        end

        Log.debug( "new_from_addr: #{new_from_addr}" )

        return new_from_addr

      else

        Log.error "INVALID SENDER ADDRESS"
        exit 1

      end

    end

  end

  def create_alias( alias_addr, real_local_addr )

    u_id = User.get( real_local_addr )["id"]

    a = Address.new( u_id, alias_addr )

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
