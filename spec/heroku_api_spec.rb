require 'spec_helper.rb'
require 'heroku_stubs'
require './lib/apis/heroku_api'

describe HerokuApi do
  let(:platform_api) do 
     heroku_double([
      5.minutes.ago
    ]) 
  end

  let!(:heroku_api) do
    allow(PlatformAPI).to receive(:connect_oauth) { platform_api }
    HerokuApi.new
  end

  describe 'deploy' do
    it 'calls out to api' do
      expect(platform_api.build).to receive(:create)

      heroku_api.deploy('sassy', 'example.com/foobar.tar.gz')
    end
  end

  describe 'web_logs' do
    it 'returns nil when the Net:HTTP call dies' do
      allow(Net::HTTP).to receive(:get) { raise EOFError }
      result = heroku_api.send(:web_logs, 'staging')
      expect(result).to be_nil
    end
  end

  describe 'last_active_at' do
    context 'with an app' do
      it 'returns nil with no log line' do
        allow(heroku_api).to receive(:web_logs)

        result = heroku_api.last_active_at('staging')

        expect(result).to be_nil
      end
    end
  end
end
