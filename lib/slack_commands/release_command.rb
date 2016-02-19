require './lib/slack_commands/slack_command'
class ReleaseCommand < SlackCommand
  def self.aliases
    %w(release give)
  end

  def initialize(options)
    super

    if @app = @arguments[0]
      raise "invalid app" unless APPS.include?(@app)
    end
  end

  def run
    if @app
      release(@app)
    else
      APPS.each do |app|
        release(app)
      end
    end
  end

  def release(app)
    claim = claims.info[app]
    if claim[:user] == @user && claim[:expires_at] > Time.now
      claims.take(app, @user, 1.minute.ago)
      send_to_slack("Releasing #{app}")
    end
  end
end
