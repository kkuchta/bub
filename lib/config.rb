# TODO: make configurable
APPS = %w(sassy fluffy staging)
APP_PREFIX = "joyable-"
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

