require './lib/slack_commands/slack_command'
class HelpCommand < SlackCommand
  def self.aliases
    %w(help halp ? h -h -help --help)
  end

  def run
    message = <<-help
`bub`: the staging box tracking tool.

`bub info` – list all known staging boxes, along with who has them claimed and when that box has last visited (according to the server logs).

`bub take sassy 3 hours` - claim the staging box named joyable-sassy for the next 3 hours. If you omit the time period, bub will assume you want the box for 1 hour.  If you omit the box name, bub will give you the first available server.

`bub release sassy` - releases your claim on joyable-sassy.  Omit the box name to release your claim on any box currently claimed by you.

`bub deploy production` - reserves a deploy lock for deploying to production. Will automatically expire after 5 minutes or a deploy has completed.

`bub help` - prints this message

Written and maintained by Kevin Kuchta.  Complaints and PRs welcome at https://github.com/kkuchta/bub.
    help

    send_to_slack('`bub help` prints available commands via direct message to you')
    send_to_slack(message, '@' + @user)
  end
end
