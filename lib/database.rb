require 'pg'
require './lib/config'

# Just a holder for the singleton DB connection.  Other classes should handle
# their own queries and whatnot.
class DB
  def self.conn
    @conn ||= PG.connect(DB_CONNECTION_STRING)
  end
end
