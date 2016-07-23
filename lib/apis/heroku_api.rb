require 'platform-api'
require './lib/config'

class HerokuApi
  APPS = %w(sassy staging) # TODO add fluffy
  def initialize
    @heroku = PlatformAPI.connect_oauth(HEROKU_API_KEY)
  end

  # Get last web activity datetime (or a map of apps to datetimes if no app is
  # specified)
  def last_active_at(app=nil)
    if app.nil?
      APPS.reduce({}) do |hash, app|
        hash[app] = last_active_at(app)
        hash
      end
    else
      log_lines = web_logs(app)
      if log_lines
        log_line = log_lines.split("\n").last
        Time.parse(log_line.strip.split(' ').first)
      else
        nil
      end
    end
  end

  def deploy(app, tarball_url)
    # TODO: set up post-deploy hooks to call back here
    puts "DEPLOY to #{app}"

    build_config = {
      source_blob: {
        url: tarball_url
      }
    }
    result = @heroku.build.create(heroku_name(app), build_config)
  end

  private

  # Look for log lines from the web process (indicating that someone's visited
  # that app recently).
  #
  # Note that when you ask heroku for 100 lines of log for dyno 'web.1', it'll
  # give you the first 100 lines of logs with everything but web.1 filtered out.
  # So, if dynos besides web.1 have been somewhat active recently, you might get
  # a completely blank result.
  #
  # So, we'll try successively bigger line counts until we find some activity
  def web_logs(app, line_count = 10**3)
    puts "Fetching #{line_count} log lines"
    return nil if line_count > 10**4

    log_session = @heroku.log_session.create(heroku_name(app), {
      dyno: 'web.1',
      lines: line_count
    })
    url = log_session['logplex_url']
    result = Net::HTTP.get(URI(url))
    if result.strip == ''
      web_logs(app, line_count * 10)
    else
      result
    end
  rescue StandardError => e
    puts "ERR: web_logs got #{e.inspect}"
  end

  def heroku_name(app)
    APP_PREFIX + app
  end

end
