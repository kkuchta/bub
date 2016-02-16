require './lib/slack_commands/slack_command'
class TakeCommand < SlackCommand
  def self.aliases
    %w(take claim)
  end

  def initialize(options)
    super

    @app = @arguments[0]
    raise "bad args" unless APPS.include?(@app = @arguments[0])

    @target_time = if amount = @arguments[1]
      amount = amount.to_i
      raise 'bad args' unless amount > 0

      increment = @arguments[2]
      unless valid_increments.include?(increment)
        raise 'bad args:' + increment
      end

      amount.send(increment.to_sym).from_now
    else
      1.hour.from_now
    end
  end

  def valid_increments
    %w(minute hour day week month).reduce([]) do |valid, increment|
      valid << increment + 's'
      valid << increment
      valid
    end
  end

  def run
    claims.take(@app, @user, @target_time)
    message = "#{@user} has #{@app} for the next #{time_ago_in_words(@target_time)}"
    send_to_slack(message)
  end
end
