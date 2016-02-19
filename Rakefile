require 'pg'
require './lib/config'

namespace :db do
  task :create do
    conn = PG.connect(DB_CONNECTION_STRING)
    conn.exec('DROP TABLE IF EXISTS claims')

    conn.exec('
      CREATE TABLE IF NOT EXISTS claims (
        app varchar(255),
        "user" varchar(255),
        expires_at timestamp,
        claimed_at timestamp
      )
    ')
  end
end
