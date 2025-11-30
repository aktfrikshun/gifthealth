# frozen_string_literal: true

# Configure importmap-rails
Rails.application.config.importmap.draw do
  # Pin application and dependencies
  pin "application", preload: true
  pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js"
  
  # Pin all controllers
  pin_all_from "app/javascript/controllers", under: "controllers"
end
