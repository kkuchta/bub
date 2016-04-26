require './lib/slack_commands/slack_command'

# Supports `bub deploy production`. Will reserve a server and remove the
# reservation when we receive a heroku deploy hook.
#
class DeployCommand < SlackCommand
  DEPLOYABLE_SERVERS = %w(production prod)
  RESERVABLE_SERVERS = %w(sassy fluffy staging)
  EXPIRATION_THRESHOLD = 300

  def self.aliases
    %w(launch deploy)
  end

  def initialize(options)
    super
    @server = @arguments.shift
  end

  def run
    return unless validate_params
    @server = 'production'
    if deploys.deploy(@server, @user, Time.now + EXPIRATION_THRESHOLD)
      send_to_slack "<@#{@user}> is deploying to #{@server}!"
    else
      user = deploys.deploying_user(@server)
      send_to_slack "Sorry, <@#{@user}>, it looks like #{user} is already deploying to #{@server}."
    end
  end

  private

  def validate_params
    message = \
      if !@server
        "To deploy to production, please type 'bub deploy production"\
          "', <@#{@user}>"
      elsif RESERVABLE_SERVERS.include?(@server)
        "Please reserve that server using bub take, <@#{@user}>"
      elsif !DEPLOYABLE_SERVERS.include?(@server)
        'Did you mean production?'
      end
    if message
      send_to_slack message
      false
    else
      true
    end
  end
end
