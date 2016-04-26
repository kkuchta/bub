require 'pg'
require './lib/config'
require './lib/deploys'

def add_deploy(conn, user, app, expires_at)
  conn.exec_params('insert into deploys ("user", app, expires_at)'\
    'values ($1, $2, $3);', [user, app, expires_at])
end

describe Deploys do
  let(:deploy) { Deploys.new }
  let(:conn) { deploy.conn }
  let(:user) { 'kevin' }
  let(:app) { 'production' }
  let(:expires_at) { Time.now - 3000 }
  before do
    clean_database
    add_deploy(conn, user, app, expires_at)
  end
  describe '#expire_old_deploys' do
    before { add_deploy(conn, user, app, Time.now + 3) }
    it 'should remove old deploys' do
      expect(deploy.num_deploys(app)).to eql(2)
      deploy.expire_old_deploys
      expect(deploy.num_deploys(app)).to eql(1)
    end
  end
  describe '#deploying_user' do
    it 'should return the deploying user' do
      expect(deploy.deploying_user(app)).to eql('kevin')
    end
  end
  describe '#complete_deploy' do
    before { add_deploy(conn, user, 'sassy', Time.now + 3) }
    it 'should remove all deploys associated with an app' do
      expect(deploy.num_deploys(app)).to eql(1)
      expect(deploy.num_deploys('sassy')).to eql(1)
      deploy.complete_deploy(app)
      expect(deploy.num_deploys(app)).to eql(0)
      expect(deploy.num_deploys('sassy')).to eql(1)
    end
  end
end

