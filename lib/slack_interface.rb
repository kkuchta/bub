require './lib/heroku_api'
require './lib/claims'
require 'active_support'
require 'active_support/core_ext'
require 'action_view'
require 'action_view/helpers'
include ActionView::Helpers::DateHelper

# TODO: break out commands into Command subclasses
class SlackInterface
  COMMANDS = %w(test status take release help)

  def handle_slack_webhook(payload)
    params =  Rack::Utils.parse_nested_query(payload)
    err 'invalid token' unless params['token'] == ENV['SLACK_TOKEN']

    message = params['text'].sub('bub ','')
    err 'invalid message' unless message.length
    user_name = params['user_name']

    command, *arguments = message.split(' ')
    command_class = find_command_class(command)
    err("command not found: #{command}") unless command_class
    command_class.new(arguments: arguments, user: user_name).run

    #TestCommand.new(arguments: arguments).run

    return
  end

  def find_command_class(command)
    COMMANDS.each do |candidate|
      candidate_class = (candidate + 'Command').camelize.safe_constantize
      return candidate_class if candidate_class.can_handle?(command)
    end
    nil
  end

  def test_command(user, arguments)
    send_to_slack("Test: #{arguments}")
  end

  def release_command(user, arguments)
  end

  def help_command(user, arguments)
  end

  def err(msg)
    raise BubError, msg
  end

end

class SlackCommand
  def initialize(options = {})
    @user = options[:user]
    @arguments = options[:arguments]
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

  def self.can_handle?(command)
    aliases.include?(command)
  end

  def claims
    @claims ||= Claims.new
  end

  def heroku
    @heroku ||= HerokuApi.new(ENV['HEROKU_API_KEY'])
  end

end

class TestCommand < SlackCommand
  def self.aliases
    ['test']
  end
  def run
    send_to_slack(@arguments.join(' '))
  end
end

class StatusCommand < SlackCommand
  def self.aliases
    %w(status info list)
  end

  def run
    APPS.map do |app|
      claim = claims.info(app)
      claim_message =
        if claim.nil?
          "*never claimed*"
        elsif claim[:expires_at] > Time.now
          "*#{@user}'s* for the next #{time_ago_in_words(claim[:expires_at])}"
        else
          "*free*"
        end

      inactive_time = heroku.ps(app)
      active_message = inactive_time ? time_ago_in_words(inactive_time) : "a while"

      message = "#{app}: #{claim_message} (last active #{active_message} ago)"
      send_to_slack(message)
    end
  end
end

class TakeCommand < SlackCommand
  def self.aliases
    %w(take claim)
  end

  def run
    raise "bad args" unless APPS.include?(app = @arguments.shift)

    amount = @arguments.shift
    if amount
      amount = amount.to_i
      raise 'bad args' unless amount > 0

      valid_increments = %w(minute hour day week month).reduce([]) do |valid, increment|
        valid << increment + 's'
        valid << increment
        valid
      end

      increment = @arguments.shift
      unless valid_increments.include?(increment)
        raise 'bad args:' + increment
      end

      target_time = amount.send(increment.to_sym).from_now
    else
      target_time = 1.hour.from_now
    end

    claims.take(app, @user, target_time)
    message = "#{@user} has #{app} for the next #{time_ago_in_words(target_time)}"
    send_to_slack(message)
  end
end

class ReleaseCommand < SlackCommand
  def self.aliases
    %w(release give)
  end

  def run
    app = @arguments.shift
    if app
      raise "invalid app" unless APPS.include?(app)
      relase(app)
    else
      APPS.each do |app|
        take(@user, app)
      end
    end
  end

  def release(app)
    claim = claims.info(app)
    if claim[:user] == @user && claim[:expires_at] > Time.now
      claims.take(app, @user, 1.minute.ago)
      send_to_slack("Releasing #{app}")
    end
  end
end

class HelpCommand < SlackCommand
  def self.aliases
    %w(help halp ? h -h -help --help)
  end

  def run
    send_to_slack <<-help
`bub`: the staging box tracking tool.

`bub info` – list all known staging boxes, along with who has them claimed and when that box has last visited (according to the server logs).

`bub take sassy 3 hours` - claim the staging box named joyable-sassy for the next 3 hours. If you omit the time period, bub will assume you want the box for 1 hour.

`bub release sassy` - releases your claim on joyable-sassy.  Omit the box name to release your claim on any box currently claimed by you.

`bub help` - prints this message
    help
  end
end
