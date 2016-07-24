require_relative '../http_post_interface'
Dir['./lib/slack_commands/*.rb'].each { |file| require file }

class HerokuInterface < HttpPostInterface
  def handle_heroku_webhook(payload)
    params = Rack::Utils.parse_nested_query(payload)
    user = find_user(params)
    server = server(params)
    release = "#{params['release']} " if params['release']

    deploys.complete_deploy(server)
    message = [
      user,
      'just finished deploying',
      release,
      'to',
      server
    ].compact.join(' ')

    SlackApi.send_to_slack(message)
  end

  private

  def find_user(params)
    user = params['user'].split('@')[0]

    # This was deployed via the bub slack interface, meaning the "user" heroku
    # gives us is useless (just the bub user).  Let's use whoever has this
    # box claimed instead.
    if user.include?('bubbot')
      user = claims.info[server(params)]&.[](:user) || user
    end
    user
  end

  def server(params)
    params['app'].gsub('joyable-', '')
  end

  def deploys
    @deploys ||= Deploys.new
  end

  def claims
    @claims ||= Claims.new
  end

  def github
    @github ||= GithubApi.new
  end
end

