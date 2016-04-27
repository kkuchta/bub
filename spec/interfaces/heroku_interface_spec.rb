require 'pg'
require './lib/config'
require './lib/interfaces/heroku_interface'

def add_deploy(conn, user, app, expires_at)
  conn.exec_params('insert into deploys ("user", app, expires_at)'\
    'values ($1, $2, $3);', [user, app, expires_at])
end

describe HerokuInterface do
  let(:deploy) { Deploys.new }
  let(:payload) do
    'app=joyable-test&user=kevin@joyable.com&url=http%3A%2F%2Fjoyable-test.herokuapp.com' \
    '&head=0b5fb19&head_long=0b5fb19f982713183e27abb3a7231018169a150d&git_log=*example' \
    '&release=the%20super%20release'
  end

  describe '#handle_heroku_webhook' do
    subject { HerokuInterface.new.handle_heroku_webhook(payload) }
    it 'should send a message to slack with the user, revision and server' do
      expect(SlackApi).to receive(:send_to_slack)
        .with('kevin just finished deploying the super release to test.')
      subject
    end
  end
end

