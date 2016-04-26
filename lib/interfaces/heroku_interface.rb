require_relative '../http_post_interface'
Dir['./lib/slack_commands/*.rb'].each { |file| require file }

class HerokuInterface < HttpPostInterface
  def handle_heroku_webhook(payload)
    params = Rack::Utils.parse_nested_query(payload)
    user = params['user'].split('@')[0]
    release = "#{params['release']} " if params['release']
    server = params['url'].split('/').last.split('.').first[8..-1]

    deploys.complete_deploy(server)

    SlackCommand
      .new
      .send_to_slack("#{user} just finished deploying #{release}to #{server}.")
  end

  private

  def deploys
    @deploys ||= Deploys.new
  end
end

