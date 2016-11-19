require 'net/http'
require 'uri'
require 'json'
require './lib/config.rb'
Dir['./lib/interfaces/*.rb'].each { |file| require file }
Dir['./lib/apis/*.rb'].each { |file| require file }

class BubError < StandardError
end

class BubBot
  def call(env)
    request = Rack::Request.new(env)

    if request.path == '/slack_hook' && request.post?
      SlackInterface.new.handle_slack_webhook(request.body.read)
      return [200, {}, []]
    elsif request.path == '/heroku_hook' && request.post?
      HerokuInterface.new.handle_heroku_webhook(request.body.read)
      return [200, {}, []]
    # elsif
      # If you want to add a web interface to this tool, this is the place to
      # put it
    else
      err 'invalid request'
    end
  rescue BubError => e
    puts "Err: #{e.message}"
    return [400, {}, [e.message]]
  end

  def err(msg)
    raise BubError, msg
  end

end
