require 'pg'
require './lib/config'

# Stores who's claimed what between requests.  It uses file storage, which means:
#   - The claims will by wiped by heroku on deploy and/or restart
#   - Concurrent access might not do what you expect (unless I add a bunch of
#     code that wouldn't be worth it)
# So, TODO: replace this with a db or a key-value store or something.
class Claims
  STORAGE_FILENAME = '/tmp/bub_claims'

  # Claim this app, overwriting any previous claim
  def take(app, user, expires_at)

    # Postgre 9.4 doesn't support upsert yet, so just insert newer rows in the
    # db.  Then use an annoying query to get the newest for each app in info().
    conn.prepare('taker', '
      INSERT INTO claims (app, "user", expires_at, claimed_at)
      values ($1, $2, $3, $4)
    ')
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
    @conn ||= PG.connect(DB_CONNECTION_STRING)
  end
end
