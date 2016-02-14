require 'platform-api'

class HerokuApi
  def initialize(api_key)
    puts "API key = #{api_key}"
    @heroku = PlatformAPI.connect_oauth(api_key)
    @apps = %w(joyable-sassy joyable-staging)
  end

  def ps
    @apps.map do |app|
      # 10 lines, since the first couple lines are blank for some reason?
      #puts "results for #{app}: #{result}"
      log_line = web_logs(app).split("\n").last
      if log_line
        log_time = time_ago(Time.parse(log_line.strip.split(' ').first))
        [app, log_time]
      else
        [app, 'a while ago']
      end
    end
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

    log_session = @heroku.log_session.create(app, {dyno: 'web.1', lines: line_count})
    url = log_session['logplex_url']
    result = Net::HTTP.get(URI(url))
    if result.strip == ''
      web_logs(app, line_count * 10)
    else
      result
    end
  end

  # Cheap knockoff version of time_ago_in_words from ActionView
  def time_ago(time)
    seconds_ago = (Time.now - time).round
    return "#{seconds_ago} seconds ago" unless seconds_ago > 60

    minutes_ago = (seconds_ago / 60).round
    return "#{minutes_ago} minutes ago" unless minutes_ago > 60

    hours_ago = (minutes_ago / 60).round
    return "#{hours_ago} hours ago" unless hours_ago > 24

    days_ago = (hours_ago / 24).round
    return "#{days_ago} days ago" unless days_ago > 30

    months_ago = (days_ago / 30).round
    return "#{months_ago} months ago"
  end
end
