require 'pg'
require './lib/config'

# Stores who is deploying
class Deploys
  STORAGE_FILENAME = '/tmp/bub_deploys'

  def deploy(app, user, expires_at)
    expire_old_deploys
    if num_deploys(app) == 0
      begin
        conn.prepare('deploy', '
          INSERT into deploys (app, "user", expires_at)
          VALUES ($1, $2, $3)
        ')
      end
      conn.exec_prepared('deploy', [app, user, expires_at])
    end
  end

  def num_deploys(app)
    conn.exec_params('SELECT COUNT(*) FROM deploys WHERE app = $1;', [app])[0]['count'].to_i
  end

  def complete_deploy(app)
    conn.exec_params('DELETE FROM deploys WHERE app = $1;', [app])
  end

  # in case something happens with the webhook, prefer to be able to deploy
  # after some time has passed
  def expire_old_deploys
    conn.exec_params('DELETE FROM deploys WHERE expires_at < NOW();')
  end

  def deploying_user(app)
    user = conn.exec_params('SELECT * FROM deploys WHERE app = $1;', [app])
    puts user[0].inspect
    user[0]['user']
  end

  def info
    result = conn.exec('SELECT * FROM deploys WHERE expires_at > NOW()')

    results = []
    result.each_with_object({}) do |row|
      results << row
    end
    results
  end

  def conn
    @conn ||= PG.connect(DB_CONNECTION_STRING)
  end
end

