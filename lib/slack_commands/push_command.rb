require './lib/slack_commands/slack_command'
require './lib/apis/github_api'

class PushCommand < SlackCommand
  def self.aliases
    %w(push)
  end

  def initialize(options)
    super

    # Accepts either `push sassy kk_onboarding` or `push kk_onboarding sassy`.
    # Don't name your branches after staging servers.  :P
    arg1, arg2 = @arguments
    if APPS.include?(arg1) && arg2.present?
      @app = arg1
      @branch = arg2
    elsif APPS.include?(arg2) && arg1.present?
      @app = arg2
      @branch = arg1
    end
    raise "no recognizable app" unless @app
  end

  def run
    binding.pry
    unless github.branch_exists?(@branch)
      send_to_slack("Branch `#{@branch}` wasn't found on github")
      return
    end
    tarball_url = github.get_tarball_url(@branch)

    heroku.deploy(@app, tarball_url)
    send_to_slack("Pushing `#{@branch}` to #{@app}")
  end
end
