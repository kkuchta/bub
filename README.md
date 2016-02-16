# bub
Bub: a tool for claiming heroku boxes.

![](http://i.imgur.com/sda5apD.png)

Problem: You have several heroku projects that you use as staging/testing servers, and several engineers that use them as-needed.  Each engineer needs to know whether any given box is in use (so they don't accidentally clobber someone else's changes).

Solution: Bub.  Hook it up to your slack channel and use it to track who's using what server.

## Installing

1. Clone this repo
2. Open `lib/bub_bot.rb` and:
  - modify the `APPS` constant to be the short names of your servers (eg `staging-1` )
  - modify the `APP_PREFIX` constant to be whatever you prefix your shortnames with to get your actual heroku project names (eg "initech-" if your server is called `initech-staging-1`)
3. Push to heroku
4. Set up your config variables (`heroku config:set FOO=bar`)
  - `SLACK_TOKEN=AbCdEf123456`
  - `SLACK_URL="https://hooks.slack.com/services/ABC123/DEF456/gHiJk789`
  - `HEROKU_API_KEY=321dd6dd-1f48-4ca6-9b31-7f5bc8a129f3`

## Contributing
TODO
## LICENSE
MIT
TODO: add license file
