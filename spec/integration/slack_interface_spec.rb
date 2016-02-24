require 'spec_helper.rb'
require 'platform-api'
require './lib/slack_interface'
require 'heroku_stubs'

describe SlackInterface do
  let(:interface) { SlackInterface.new }

  describe 'status command' do
    before do
      allow(PlatformAPI).to receive(:connect_oauth) { heroku_double([
        5.minutes.ago
      ]) }
    end
    it 'Shows status' do

      expect_any_instance_of(SlackCommand).to receive(:send_to_slack).with('sassy: *free* (last active 5 minutes ago)')
      expect_any_instance_of(SlackCommand).to receive(:send_to_slack).with('staging: *free* (last active 5 minutes ago)')

      interface.handle_slack_webhook({
        user_name: 'kevin',
        text: 'bub status',
        token: SLACK_TOKEN
      }.to_query)
    end

    it 'works even when the heroku dies and returns nil' do
      allow_any_instance_of(HerokuApi).to receive(:last_active_at)

      expect_any_instance_of(SlackCommand).to receive(:send_to_slack).with('sassy: *free* (last active a while ago)')
      expect_any_instance_of(SlackCommand).to receive(:send_to_slack).with('staging: *free* (last active a while ago)')

      interface.handle_slack_webhook({
        user_name: 'kevin',
        text: 'bub status',
        token: SLACK_TOKEN
      }.to_query)
    end
  end
end
