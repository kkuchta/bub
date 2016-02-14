require 'net/http'
require 'uri'
require 'json'

class BubError < StandardError
end

class BubBot
  def call(env)
    puts "Started"
    request = Rack::Request.new(env)

    err 'post only' unless request.post?
    body = request.body.read
    params =  Rack::Utils.parse_nested_query(body)
    err 'invalid token' unless params['token'] == ENV['SLACK_TOKEN']

    message = params['text'].sub('bub ','')
    err 'invalid message' unless message.length

    command, arguments = message.split(' ', 2)
    valid_commands = %w(test status)
    err "invalid command" unless valid_commands.include? command

    send(:"#{command}_command", arguments)

    return [200, {}, []]
  rescue BubError => e
    puts "Err: #{e.message}"
    return [400, {}, [e.message]]
  rescue StandardError => e
    #puts "Err: #{e.message}"
    #return [500, {}, []]
    raise e
  end

  def err(msg)
    raise BubError, msg
  end

  def test_command(arguments)
    send_message("Test: #{arguments}")
  end

  def send_message(message)
    uri = URI.parse(ENV['SLACK_URL'])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      text: message,
      username: 'bub'
    }.to_json

    http.request(request)
  end
end
