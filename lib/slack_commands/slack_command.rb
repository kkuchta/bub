class SlackCommand
  def initialize(options = {})
    @user = options[:user]
    @arguments = options[:arguments] || []
  end

  def send_to_slack(message, channel = nil)
    uri = URI.parse(SLACK_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    body = {
      text: message,
      username: 'bub',
    }
    body[:channel] = channel if channel
    request.body = body.to_json

    http.request(request)
  end

  def self.can_handle?(command)
    aliases.include?(command)
  end

  def claims
    @claims ||= Claims.new
  end

  def heroku
    @heroku ||= HerokuApi.new
  end

end
