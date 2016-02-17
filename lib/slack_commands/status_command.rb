require './lib/slack_commands/slack_command'
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
          "*#{claim[:user]}'s* for the next #{time_ago_in_words(claim[:expires_at])}"
        else
          "*free*"
        end

      inactive_time = heroku.last_active_at(app)
      active_message = inactive_time ? time_ago_in_words(inactive_time) : "a while"

      message = "#{app}: #{claim_message} (last active #{active_message} ago)"
      send_to_slack(message)
    end
  end
end
