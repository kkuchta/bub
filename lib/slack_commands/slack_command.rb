class SlackCommand
  def self.can_handle?(command)
    aliases.include?(command)
  end

  def initialize(options = {})
    @user = options[:user]
    @channel = '#' + options[:channel] if options[:channel]
    @arguments = options[:arguments] || []
  end

  def send_to_slack(message, channel = (@channel || nil))
    body = {
      text: message,
      username: 'bub',
    }
    body[:channel] = channel if channel
    slack_http_request(body)
  end

  def claims
    @claims ||= Claims.new
  end

  def heroku
    @heroku ||= HerokuApi.new
  end

  private

  def slack_http_request(body)
    uri = URI.parse(SLACK_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request.body = body.to_json

    http.request(request)
  end

end
