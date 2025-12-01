# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  config.action_controller.raise_on_missing_callback_actions = true

  # Allow GitHub Codespaces URLs for CSRF protection
  config.hosts << /[a-z0-9-]+\.app\.github\.dev/
  config.action_controller.forgery_protection_origin_check = false
end
