require 'spec_helper.rb'
require 'platform-api'
require './lib/slack_interface'
require 'heroku_stubs'
require 'timecop'

# TODO: don't hardcode 'bub'
# TODO: don't hardcode server names
# TODO: this file is sorta testing everything.  Switch to more focused unit
# specs and only have a few high-level integration specs here.
describe SlackInterface do
  let(:user) { 'kevin' }
  let(:interface) { SlackInterface.new }
  def webhook_args(options)
    {
        user_name: user,
        text: 'bub status',
        token: SLACK_TOKEN,
        channel_name: 'general'
    }.merge(options).to_query
  end

  describe 'status command' do
    before do
      allow(PlatformAPI).to receive(:connect_oauth) { heroku_double([
        5.minutes.ago
      ]) }
    end

    it 'prints in the same channel the command was received from' do
      channel = 'some_channel'
      expect_any_instance_of(SlackCommand)
        .to receive(:slack_http_request)
        .at_least(:once)
        .with(hash_including(channel: '#' + channel))

      interface.handle_slack_webhook(webhook_args({
        text: 'bub status',
        channel_name: channel
      }))
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

  # TODO: DRY this up
  describe 'take command' do
    let(:claims_info) do
      {
        'sassy' => { user: 'kevin', expires_at: 2.hours.from_now },
        'staging' => { user: 'kevin', expires_at: 1.hour.ago },
        'fluffy' => { user: 'kevin', expires_at: 1.hour.from_now }
      }
    end
    around :each do |example|
      Timecop.freeze do
        example.run
      end
    end

    before :each do
      allow_any_instance_of(SlackCommand)
        .to receive(:send_to_slack)
    end

    context 'with no arguments' do
      it 'takes the first available server for 1 hour' do
        allow_any_instance_of(Claims) .to receive(:info) { claims_info }
        expect_any_instance_of(Claims)
          .to receive(:take)
          .with('staging', user, 1.hour.from_now)

        interface.handle_slack_webhook(webhook_args({
          text: 'bub take'
        }))
      end

      it 'doesn\'t take any servers if none are available' do
        claims_info = {
          'sassy' => { user: 'kevin', expires_at: 2.hours.from_now },
          'staging' => { user: 'kevin', expires_at: 1.hour.from_now },
          'fluffy' => { user: 'kevin', expires_at: 1.day.from_now }
        }

        allow_any_instance_of(Claims).to receive(:info) { claims_info }

        expect_any_instance_of(Claims).not_to receive(:take)
        expect_any_instance_of(SlackCommand).to receive(:send_to_slack).with(anything)

        interface.handle_slack_webhook(webhook_args({
          text: 'bub take'
        }))
      end
    end
    context 'with one argument' do
      it 'takes the first available server for the specified time' do
        allow_any_instance_of(Claims) .to receive(:info) { claims_info }
        expect_any_instance_of(Claims)
          .to receive(:take)
          .with('staging', user, 3.days.from_now)

        interface.handle_slack_webhook(webhook_args({
          text: 'bub take 3 days'
        }))
      end

      it 'takes the specified server for 1 hour' do
        expect_any_instance_of(Claims)
          .to receive(:take)
          .with('sassy', user, 1.hour.from_now)

        interface.handle_slack_webhook(webhook_args({
          text: 'bub take sassy'
        }))
      end
    end

    context 'with two arguments' do
      it 'takes the specified server for the specified time' do
        expect_any_instance_of(Claims)
          .to receive(:take)
          .with('sassy', user, 3.days.from_now)

        interface.handle_slack_webhook(webhook_args({
          text: 'bub take sassy 3 days'
        }))
      end
    end
  end
end
