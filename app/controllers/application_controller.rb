# frozen_string_literal: true

# Base controller providing common functionality for all controllers
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
