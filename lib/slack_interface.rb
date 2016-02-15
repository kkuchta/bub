require './lib/heroku_api'
require './lib/claims'
require 'active_support'
require 'active_support/core_ext'
require 'action_view'
require 'action_view/helpers'
include ActionView::Helpers::DateHelper

# TODO: break out commands into Command subclasses
class SlackInterface

  def handle_slack_webhook(payload)
    params =  Rack::Utils.parse_nested_query(payload)
    err 'invalid token' unless params['token'] == ENV['SLACK_TOKEN']

    message = params['text'].sub('bub ','')
    err 'invalid message' unless message.length
    user_name = params['user_name']

    command, *arguments = message.split(' ')
    valid_commands = %w(test status ps take help release)
    err "invalid command #{command}" unless valid_commands.include? command

    send(:"#{command}_command", user_name, arguments)
  end

  def heroku
    @heroku ||= HerokuApi.new(ENV['HEROKU_API_KEY'])
  end

  def claims
    @claims ||= Claims.new
  end

  def test_command(user, arguments)
    send_to_slack("Test: #{arguments}")
  end

  def release_command(user, arguments)
    app = arguments.shift
    if app
      raise "invalid app" unless HerokuApi::APPS.include?(app)
      claim = claims.info(app)
      if claim[:user] == user && claim[:expires_at] > Time.now
        claims.take(app, user, 1.minute.ago)
        send_to_slack("Releasing #{app}")
      end
    else
      HerokuApi::APPS.each do |app|
        release_command(user, [app])
      end
    end
  end

  def help_command(user, arguments)
    send_to_slack <<-help
Bub: the staging box tracking tool.

`bub info` – list all known staging boxes, along with who has them claimed and when that box has last visited (according to the server logs).

`bub take sassy 3 hours` - claim the staging box named joyable-sassy for the next 3 hours. If you omit the time period, bub will assume you want the box for 1 hour.

`bub release sassy` - (TODO) releases your claim on joyable-sassy.  Omit the box name to release your claim on any box currently claimed by you.
    help
  end

  def status_command(user, arguments)
    HerokuApi::APPS.map do |app|
      claim = claims.info(app)
      claim_message =
        if claim.nil?
          "*never claimed*"
        elsif claim[:expires_at] > Time.now
          "*#{user}'s* for the next #{time_ago_in_words(claim[:expires_at])}"
        else
          "*free*"
        end

      inactive_time = heroku.ps(app)
      active_message = inactive_time ? time_ago_in_words(inactive_time) : "a while"

      message = "#{app}: #{claim_message} (last active #{active_message} ago)"
      send_to_slack(message)
    end
  end

  def take_command(user, arguments)
    raise "bad args" unless HerokuApi::APPS.include?(app = arguments.shift)

    amount = arguments.shift
    if amount
      amount = amount.to_i
      raise 'bad args' unless amount > 0

      valid_increments = %w(minute hour day week month).reduce([]) do |valid, increment|
        valid << increment + 's'
        valid << increment
        valid
      end

      increment = arguments.shift
      unless valid_increments.include?(increment)
        raise 'bad args:' + increment
      end

      target_time = amount.send(increment.to_sym).from_now
    else
      target_time = 1.hour.from_now
    end

    claims.take(app, user, target_time)
    message = "#{user} has #{app} for the next #{time_ago_in_words(target_time)}"
    send_to_slack(message)
  end

  def ps_command(user, aruments)
    inactive_times = heroku.ps
    message = inactive_times.map do |app, inactive_time|
      time_ago = inactive_time ? time_ago_in_words(inactive_time) : "a while"
      "#{app}: last active #{time_ago} ago"
    end.join("\n")
    send_to_slack(message)
  end

  def send_to_slack(message)
    uri = URI.parse(ENV['SLACK_URL'])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      text: message,
      username: 'bub'
    }.to_json

    http.request(request)
  end

  def err(msg)
    raise BubError, msg
  end

end
