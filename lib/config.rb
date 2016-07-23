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

# Create a github user with read-only access to your repo.  Then generate a
# personal access token (https://github.com/settings/tokens) from that user
# and put it here.
GITHUB_USER = ENV['GITHUB_USER']
GITHUB_TOKEN = ENV['GITHUB_TOKEN']

# The repo to read, in username/branch format, eg: `facebook/react`
GITHUB_REPO = ENV['GITHUB_REPO']
