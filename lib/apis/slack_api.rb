class SlackApi
  def self.send_to_slack(message, channel = nil)
    body = {
      text: message,
      username: 'bub'
    }
    body[:channel] = channel if channel
    slack_http_request(body)
  end

  def self.slack_http_request(body)
    uri = URI.parse(SLACK_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request.body = body.to_json

    http.request(request)
  end

  private_class_method :slack_http_request
end

