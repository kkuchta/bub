class SlackCommand
  def self.can_handle?(command)
    aliases.include?(command)
  end

  def initialize(options = {})
    @user = options[:user]
    @channel = '#' + options[:channel] if options[:channel]
    @arguments = options[:arguments] || []
  end

  def send_to_slack(message, channel = nil)
    SlackApi.send_to_slack(message, channel || @channel)
  end

  def claims
    @claims ||= Claims.new
  end

  def deploys
    @deploys ||= Deploys.new
  end

  def heroku
    @heroku ||= HerokuApi.new
  end

  def github
    @github ||= GithubApi.new
  end

  def aptible
    @aptible ||= AptibleApi.new
  end
end
