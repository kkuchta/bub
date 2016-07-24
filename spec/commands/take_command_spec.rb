require 'spec_helper.rb'
require './lib/slack_commands/take_command'

describe TakeCommand do
  let(:command) { TakeCommand.new(user: 'kevin', channel: 'general', arguments: args) }
  around do |example|
    Timecop.freeze { example.run }
  end
  before do
    allow_any_instance_of(TakeCommand).to receive(:send_to_slack)
    allow_any_instance_of(GithubApi).to receive(:identifier_exists?) { true }
  end

  context 'with server specified' do
    let(:args) { %w(sassy) }

    it 'claims that server' do
      expect_any_instance_of(Claims).to receive(:take).with('sassy', 'kevin', 1.hour.from_now)
      command.run
    end

    context 'with time specified' do
      let(:args) { %w(sassy 2 days) }

      it 'claims that server for that time' do
        expect_any_instance_of(Claims).to receive(:take).with('sassy', 'kevin', 2.days.from_now)
        command.run
      end

      context 'with deploy specified' do
        let(:args) { %w(sassy 2 days deploy master) }

        it 'claims that server for that time and deployts' do
          expect_any_instance_of(Claims).to receive(:take).with('sassy', 'kevin', 2.days.from_now)
          expect_any_instance_of(GithubApi).to receive(:get_tarball_url).with('master') { 'some_url' }
          expect_any_instance_of(HerokuApi).to receive(:deploy).with('sassy', 'some_url')

          command.run
        end
      end
    end
  end
end
