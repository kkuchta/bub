require 'pg'
require './lib/config'

# Just a holder for the singleton DB connection.  Other classes should handle
# their own queries and whatnot.
class DB
  def self.conn
    # Clear out the connection if for some reason we disconnected (happens after a fork)
    @conn = nil unless DB.active?
    @conn ||= PG.connect(DB_CONNECTION_STRING)
  end

  # Is this connection alive and ready for queries?
  def self.active?
    @conn && @conn.exec('SELECT 1')
    true
  rescue PGError
    false
  end
end
