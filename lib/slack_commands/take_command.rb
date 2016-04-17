require './lib/slack_commands/slack_command'

# Supports `bub take staging 3 hours`, and a number of variants on that:
#   `bub take`
#   `bub take 1 hour staging`
#   `bub take staging until tomorrow` <- # TODO
#
# Admittedly, the componentize system is overkill here, but since we only have
# two components (time and app), but it'd work for any number of different
# components.  Maybe use this for more complex commands later?
class TakeCommand < SlackCommand
  def self.aliases
    %w(take claim)
  end

  def initialize(options)
    super

    components = componentize_args(@arguments)

    time_component = components.find { |component| component[:type] == 'time' }
    app_component = components.find { |component| component[:type] == 'app' }

    @target_time = time_component.try(:[], :value) || 1.hour.from_now
    @app = app_component.try(:[], :value) || first_available_app
  end

  def run
    unless @app
      send_to_slack("Sorry, no servers are available.")
      return
    end

    claims.take(@app, @user, @target_time)
    message = "#{@user} has #{@app} for the next #{time_ago_in_words(@target_time)}"
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
      if arg0 == 'for'
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

    # component, remaining_args = if arg0 == for
    #   componentize_time(arguments - arg0)
    # elseif arg0 is integer
    #   componentize_time(arguments)
    # elseif arg0 == 'until'
    #   componentize_until(arguments - arg0)
    # elsif arg0 is app
    #   componentize_app(arg0)
    # else
    #   raise "didn't understand arg0"
    # end
    # component + componentize_args(remaining_args)
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
