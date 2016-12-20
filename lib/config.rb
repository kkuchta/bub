# TODO: make configurable
HEROKU_APPS = %w()
APTIBLE_APPS = %w(gyro burrito hotdog canolli)
APPS = HEROKU_APPS + APTIBLE_APPS
APP_VENDOR = "joyable"
APP_PREFIX = "#{APP_VENDOR}-"
APTIBLE_APP = "#{APP_PREFIX}rails"
DB_CONNECTION_STRING = ENV['DATABASE_URL'] || 'dbname=bub_bot'

# Used to verify incoming web requests from slack
# https://api.slack.com/outgoing-webhooks
SLACK_TOKEN = ENV['SLACK_TOKEN']

# Used to send messages to slack
# https://api.slack.com/incoming-webhooks
SLACK_URL = ENV['SLACK_URL']

# Used to get info from heroku
# https://devcenter.heroku.com/articles/platform-api-reference
HEROKU_API_KEY = ENV['HEROKU_API_KEY']

# Create a github user with read-only access to your repo.  Then generate a
# personal access token (https://github.com/settings/tokens) from that user
# and put it here.
GITHUB_USER = ENV['GITHUB_USER']
GITHUB_TOKEN = ENV['GITHUB_TOKEN']

# The repo to read, in username/branch format, eg: `facebook/react`
GITHUB_REPO = ENV['GITHUB_REPO']

GIT_KEY = ENV['GIT_KEY']

if GIT_KEY
  # The private key is base64 encoded to deal with issues with new lines in env vars on heroku
  require 'base64'
  decoded_key = Base64.strict_decode64(GIT_KEY)

  FileUtils.rm_rf('git_key')
  File.open('git_key', 'w') { |file| file.write decoded_key } 
  FileUtils.chmod(0400, 'git_key')
end
