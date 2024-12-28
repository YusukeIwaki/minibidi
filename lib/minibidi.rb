require "minibidi/version"

require 'minibidi/browser'
require 'minibidi/browsing_context'
require 'minibidi/browser_process'
require 'minibidi/firefox_launcher'
require 'minibidi/input'
require 'minibidi/keyboard_action_queue'
require 'minibidi/mouse_action_queue'
require 'minibidi/realm'

module Minibidi
  class LaunchError < StandardError ; end
end
