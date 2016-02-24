require 'spec_helper.rb'
require 'heroku_stubs'
require './lib/heroku_api'

describe HerokuApi do
  let!(:heroku_api) do
    allow(PlatformAPI).to receive(:connect_oauth) { heroku_double([
      5.minutes.ago
    ]) }
    HerokuApi.new
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
