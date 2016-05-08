require 'pg'
require './lib/config'
require './lib/interfaces/heroku_interface'

describe HerokuInterface do
  describe '#handle_heroku_webhook' do
    let(:deploy) { Deploys.new }
    let(:env) { 'production' }
    let(:payload) do
      "app=joyable-#{env}&user=kevin@joyable.com&url=http%3A%2F%2Fjoyable-test.herokuapp.com" \
      "&head=0b5fb19&head_long=0b5fb19f982713183e27abb3a7231018169a150d&git_log=*example" \
      "&release=the%20super%20release"
    end
    subject { HerokuInterface.new.handle_heroku_webhook(payload) }
    context 'production' do
      it 'should send a message to slack with the user, revision and server' do
        expect(SlackApi).to receive(:send_to_slack)
          .with('kevin just finished deploying the super release to production.')
        subject
      end
    end
    context 'not production' do
      let(:env) { 'test' }
      it 'should not send a message to slack' do
        expect(SlackApi).to_not receive(:send_to_slack)
        subject
      end
    end
  end
end

