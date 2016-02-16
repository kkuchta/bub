require './lib/heroku_api'
require './lib/claims'
require 'active_support'
require 'active_support/core_ext'
require 'action_view'
require 'action_view/helpers'
Dir["./lib/slack_commands/*.rb"].each {|file| require file }

include ActionView::Helpers::DateHelper

class SlackInterface
  COMMANDS = %w(test status take release help)

  def handle_slack_webhook(payload)
    params =  Rack::Utils.parse_nested_query(payload)
    err 'invalid token' unless params['token'] == SLACK_TOKEN

    message = params['text'].sub('bub ','')
    err 'invalid message' unless message.length
    user_name = params['user_name']

    # Call `run` on the appropriate WhateverCommand class
    command, *arguments = message.split(' ')
    command_class = find_command_class(command)
    err("command not found: #{command}") unless command_class
    command_class.new(arguments: arguments, user: user_name).run
  end

  def find_command_class(command)
    COMMANDS.each do |candidate|
      candidate_class = (candidate + 'Command').camelize.safe_constantize
      return candidate_class if candidate_class.can_handle?(command)
    end
    nil
  end


  def err(msg)
    raise BubError, msg
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
