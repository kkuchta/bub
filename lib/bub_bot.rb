require 'net/http'
require 'uri'
require 'json'
require './lib/slack_interface'

# TODO: make configurable
APPS = %w(sassy staging)
APP_PREFIX = "joyable-"

# Used to verify incoming web requests from slack
# https://api.slack.com/outgoing-webhooks
SLACK_TOKEN = ENV['SLACK_TOKEN']

# Used to send messages to slack
# https://api.slack.com/incoming-webhooks
SLACK_URL = ENV['SLACK_URL']

# Used to get info from heroku
# https://devcenter.heroku.com/articles/platform-api-reference
HEROKU_API_KEY = ENV['HEROKU_API_KEY']

class BubError < StandardError
end

class BubBot
  def call(env)

    request = Rack::Request.new(env)

    if request.path == '/slack_hook' && request.post?
      SlackInterface.new.handle_slack_webhook(request.body.read)
      return [200, {}, []]
    # elsif
      # If you want to add a web interface to this tool, this is the place to
      # put it
    else
      err 'invalid request'
    end
  rescue BubError => e
    puts "Err: #{e.message}"
    return [400, {}, [e.message]]
  end

  def err(msg)
    raise BubError, msg
  end

end
