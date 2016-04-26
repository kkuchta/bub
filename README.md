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

Note that this thing uses file storage right now, which means that the 'claims' data gets wiped every time you deploy or restart.

## Usage
`bub info` – list all known staging boxes, along with who has them claimed and when that box has last visited (according to the server logs).  Aka `status`

`bub take sassy 3 hours` - claim the staging box named joyable-sassy for the next 3 hours. If you omit the time period, bub will assume you want the box for 1 hour. Aka `claim`

`bub release sassy` - releases your claim on joyable-sassy.  Omit the box name to release your claim on any box currently claimed by you. Aka `give`

`bub deploy production` - reserves a deploy lock for deploying to production. Will automatically expire after 5 minutes or a deploy has completed.

`bub help` - prints usage text

`bub test foo` repeats whatever you entered (eg `foo`)

## Development

1. Set up the integrations.  You'll need:

  - A slack token from (https://api.slack.com/outgoing-webhooks) for receiving messages
    - You'll need to provide slack with the url of the machine you're developing on. [ngrok](https://ngrok.com/) is a good tool for creating such a url.  Make sure the path for that url is `/slack_hook`
  - A slack url (https://api.slack.com/incoming-webhooks) for sending messages
  - A heroku platform api key (https://devcenter.heroku.com/articles/platform-api-reference)

  I recommend setting the incoming and outgoing webhooks to use a test channel so you don't spam a normal channel during development.

2. After cloning the repo, run rackup with the correct environment vars locally:

  ```
    SLACK_TOKEN=AbCdEf123456 SLACK_URL="https://hooks.slack.com/services/ABC123/DEF456/gHiJk789 HEROKU_API_KEY=321dd6dd-1f48-4ca6-9b31-7f5bc8a129f3 rackup
  ```

3. You should be all set.  Type `bub test hello` and see if bub echos it back to you.

## TODO
- Display time of last deploy for `status` command
- Allow "silly" commands, accessible from a secondary channel (eg #random)
- Allow reversible commands (eg `bub sassy release` in addition to `bub release sassy`)
- Send user error messages via PM (eg if you call `release` without any claimed boxes)
- Add a tech support slack handle (ie me) to the help command output

## LICENSE
MIT (see LICENSE file)
