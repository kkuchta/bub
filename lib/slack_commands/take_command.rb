require './lib/slack_commands/slack_command'

# Supports `bub take staging 3 hours`, and a number of variants on that:
#   `bub take`
#   `bub take 1 hour staging`
#   `bub take 1 hour staging deploy kk_some_branch`
#   `bub take staging until tomorrow` <- # TODO
#
# Actual format is:
#   `bub take (<app>) (for? <time>) (push|deploy <branch>)
#
# The order of the three elements doesn't matter.  Time is optional (defaults to
# one hour).  Deploy is optional (defaults to not deploying)
class TakeCommand < SlackCommand
  NO_SERVERS_AVAILABLE_TEXT = 'Sorry, no servers are available.'
  def self.aliases
    %w(take claim)
  end

  def initialize(options)
    super

    components = componentize_args(@arguments)

    time_component = components.find { |component| component[:type] == 'time' }
    app_component = components.find { |component| component[:type] == 'app' }
    git_component = components.find { |components| components[:type] == 'git' }

    @target_time = time_component.try(:[], :value) || 1.hour.from_now
    @app = app_component.try(:[], :value) || first_available_app
    @git = git_component&.[](:value)
  end

  def run
    unless @app
      send_to_slack(NO_SERVERS_AVAILABLE_TEXT)
      return
    end

    claims.take(@app, @user, @target_time)
    message = "#{@user} has #{@app} for the next #{time_ago_in_words(@target_time)}"

    if @git
      heroku.deploy(@app, github.get_tarball_url(@git))
      message += " (deploying `#{@git}`)"
    end

    send_to_slack(message)
  end

  private

  def first_available_app
    claims.info.find do |app, claim|
      claim[:expires_at] < Time.now
    end.try(:first)
  end

  def componentize_args(args = @arguments.clone)
    return [] if args.length == 0

    arg0 = args.shift

    component, remaining_args = 
      if %w(push deploy).include?(arg0)
        componentize_deploy(args)
      elsif arg0 == 'for'
        componentize_time(args)
      elsif (arg0.to_i) > 0
        componentize_time([arg0] + args)
      elsif (arg0 == 'until')
        raise "'until' not yet supported"
      elsif APPS.include?(arg0)
        [{type: 'app', value: arg0}, args]
      else
        raise "didn't understand '#{arg0}'"
      end

    [component] + componentize_args(remaining_args)
  end

  def componentize_deploy(args)
    args = args.clone
    git_identifier = args.shift
    unless github.identifier_exists?(git_identifier)
      raise "bad git identifier: #{git_identifier}"
    end
    [{type: 'git', value: git_identifier}, args]
  end

  def componentize_time(args)
    args = args.clone

    amount = args.shift.to_i
    raise 'bad args' unless amount > 0

    increment = args.shift
    unless valid_increments.include?(increment)
      raise 'bad args:' + increment
    end

    time = amount.send(increment.to_sym).from_now
    [{type: 'time', value: time}, args]

  end

  def valid_increments
    %w(minute hour day week month).reduce([]) do |valid, increment|
      valid << increment + 's'
      valid << increment
      valid
    end
  end
end
