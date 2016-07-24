require 'pg'
require './lib/config'
require './lib/database'

# Stores who's claimed what between requests.
class Claims
  STORAGE_FILENAME = '/tmp/bub_claims'

  # Claim this app, overwriting any previous claim
  def take(app, user, expires_at)

    # Postgre 9.4 doesn't support upsert yet, so just insert newer rows in the
    # db.  Then use an annoying query to get the newest for each app in info().
    begin
      conn.prepare('taker', '
        INSERT INTO claims (app, "user", expires_at, claimed_at)
        values ($1, $2, $3, $4)
      ')
    rescue PG::DuplicatePstatement
      # This is fine.  It happens when you call 'take' twice in the same request.
      # There doesn't seem to be any good way to check if a prepared statement
      # exists beforehand, so we're just swallong the error.
    end
    conn.exec_prepared('taker', [app, user, expires_at.utc, Time.now.utc])
  end

  # app: { user: kevin, expires_at: "2016-02-01 10:10:10 -800" }
  def info
    result = conn.exec('
      SELECT *
      FROM claims a
      INNER JOIN (
          SELECT app, MAX(claimed_at) claimed_at
          FROM claims
          GROUP BY app
      ) b ON a.app = b.app AND a.claimed_at = b.claimed_at
    ')

    result.reduce({}) do |hash, row|
      hash[row['app']] = {
        user: row['user'],
        expires_at: DateTime.parse(row['expires_at'])
      }
      hash
    end
  end

  private

  def conn
    DB.conn
  end
end
