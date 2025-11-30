# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

module Gifthealth
  class Application < Rails::Application
    config.load_defaults 8.0
    
    # Don't generate system test files
    config.generators.system_tests = nil
    
    # Enable views and assets for web interface
    config.api_only = false
    
    # Autoload paths
    config.autoload_paths += %W[#{config.root}/app/models #{config.root}/app/services #{config.root}/app/handlers]
    config.eager_load_paths += %W[#{config.root}/app/models #{config.root}/app/services #{config.root}/app/handlers]
  end
end
