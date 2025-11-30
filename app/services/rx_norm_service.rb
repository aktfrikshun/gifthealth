# frozen_string_literal: true

require 'net/http'
require 'json'

# Service for validating and searching drug names via RxNorm API
class RxNormService
  BASE_URI = 'https://rxnav.nlm.nih.gov/REST'

  # Search for drugs matching partial name (for autocomplete)
  def self.autocomplete(query, limit: 10)
    return [] if query.blank? || query.length < 2

    uri = URI("#{BASE_URI}/spellingsuggestions.json")
    uri.query = URI.encode_www_form(name: query)

    response = make_request(uri)
    return [] unless response

    suggestions = response.dig('suggestionGroup', 'suggestionList', 'suggestion') || []
    suggestions.first(limit).map do |suggestion|
      {
        name: suggestion,
        display: suggestion
      }
    end
  rescue StandardError => e
    Rails.logger.error "RxNorm autocomplete error: #{e.message}"
    []
  end

  # Validate if a drug name exists
  def self.validate_drug(drug_name)
    return false if drug_name.blank?

    uri = URI("#{BASE_URI}/drugs.json")
    uri.query = URI.encode_www_form(name: drug_name)

    response = make_request(uri)
    return false unless response

    concept_groups = response.dig('drugGroup', 'conceptGroup')
    concept_groups&.any? { |group| group['conceptProperties']&.any? }
  rescue StandardError => e
    Rails.logger.error "RxNorm validation error: #{e.message}"
    false
  end

  # Get RxCUI (RxNorm Concept Unique Identifier) for a drug
  def self.get_rxcui(drug_name)
    return nil if drug_name.blank?

    uri = URI("#{BASE_URI}/rxcui.json")
    uri.query = URI.encode_www_form(name: drug_name)

    response = make_request(uri)
    return nil unless response

    response.dig('idGroup', 'rxnormId')&.first
  rescue StandardError => e
    Rails.logger.error "RxNorm rxcui error: #{e.message}"
    nil
  end

  class << self
    private

    def make_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Get.new(uri)
      response = http.request(request)

      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error "RxNorm API request failed: #{e.message}"
      nil
    end
  end
end
