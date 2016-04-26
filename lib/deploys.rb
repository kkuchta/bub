require 'pg'
require './lib/config'

# Stores who is deploying
class Deploys
  STORAGE_FILENAME = '/tmp/bub_deploys'

  def deploy(app, user, expires_at)
    expire_old_deploys
    count = conn.exec_params('select count(*) from deploys where app = $1;', [app])
    if count[0]['count'].to_i == 0
      begin
        conn.prepare('deploy', '
          INSERT INTO deploys (app, "user", expires_at)
          values ($1, $2, $3)
        ')
      end
      conn.exec_prepared('deploy', [app, user, expires_at])
    end
  end

  def complete_deploy(app)
    conn.exec_params('delete from deploys where app = $1;', [app])
  end

  # in case something happens with the webhook, prefer to be able to deploy
  # after some time has passed
  def expire_old_deploys
    conn.exec_params('delete from deploys where expires_at < now();')
  end

  def deploying_user(app)
    user = conn.exec_params('select * from deploys where app = $1;', [app])
    puts user[0].inspect
    user[0]['user']
  end

  def info
    result = conn.exec('SELECT * FROM deploys where expires_at > now()')

    results = []
    hash = result.each_with_object({}) do |row, hash|
      results << row
    end
    results
  end

  def conn
    @conn ||= PG.connect(DB_CONNECTION_STRING)
  end
end

