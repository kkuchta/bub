require 'git'

Git.configure do |config|
  # If you need to use a custom SSH script
  config.git_ssh = './scripts/git_ssh'
end

class AptibleApi
  def deploy(user, app, branch)
    pid = Process.fork do
      puts "Starting clone of #{branch}..."
      dir = "/tmp/#{branch}+#{Time.now.to_i}"
      FileUtils.rm_rf(dir)

      begin
        g = Git.clone("git@github.com:#{GITHUB_REPO}", APP_VENDOR, path: dir, depth: 1, branch: branch)

        puts "Converting shallow clone into something pushable..."
        Kernel.system("cd #{dir}/#{APP_VENDOR}; git filter-branch -- --all")

        puts "Pushing #{branch} to #{app}..."
        g.push("git@beta.aptible.com:#{env_name(app)}/#{APTIBLE_APP}.git", "+#{branch}:master")

        puts "Done deploying #{branch} to #{app}!"

        SlackApi.send_to_slack("#{user} just finished deploying #{branch} to #{app}")
      rescue => e
        puts e
        SlackApi.send_to_slack("#{user} failed to deploy #{branch} to #{app}")
      end

      deploys.complete_deploy(app)
      FileUtils.rm_rf(dir)
    end
  end

  private

  def env_name(app)
    APP_PREFIX + app
  end

  def deploys
    @deploys ||= Deploys.new
  end

end
