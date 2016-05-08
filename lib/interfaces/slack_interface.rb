require './lib/http_post_interface'
Dir['./lib/slack_commands/*.rb'].each { |file| require file }

class SlackInterface < HttpPostInterface
  COMMANDS = %w(test status take release help deploy)

  def handle_slack_webhook(payload)
    params = Rack::Utils.parse_nested_query(payload)
    err 'invalid token' unless params['token'] == SLACK_TOKEN

    message = params['text'].sub('bub ', '')
    err 'invalid message' unless message.length
    user_name = params['user_name']

    # Call `run` on the appropriate WhateverCommand class
    command, *arguments = message.split(' ').reject(&:empty?)
    command_class = find_command_class(command)
    err("command not found: #{command}") unless command_class

    puts "Received: #{command_class}, with args (#{arguments})"
    command_class.new(
      arguments: arguments,
      user: user_name,
      channel: params['channel_name']
    ).run
  end

  def find_command_class(command)
    COMMANDS.each do |candidate|
      candidate_class = (candidate + 'Command').camelize.safe_constantize
      return candidate_class if candidate_class.can_handle?(command)
    end
    nil
  end
end

class TestCommand < SlackCommand
  def self.aliases
    ['test']
  end

  def run
    send_to_slack(@arguments.join(' '))
  end
end
