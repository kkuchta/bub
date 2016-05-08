require './lib/heroku_api'
require './lib/claims'
require './lib/deploys'
require './lib/config'
require 'active_support'
require 'active_support/core_ext'
require 'action_view'
require 'action_view/helpers'
require 'rack/utils'

include ActionView::Helpers::DateHelper

class HttpPostInterface
  private

  def err(msg)
    raise BubError, msg
  end
end

