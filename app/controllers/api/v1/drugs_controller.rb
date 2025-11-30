# frozen_string_literal: true

# API controller for drug search autocomplete
module Api
  module V1
    # Handles drug name autocomplete and validation via RxNorm API
    class DrugsController < ActionController::API
      def autocomplete
        query = params[:query]

        if query.blank? || query.length < 2
          render json: []
          return
        end

        results = RxNormService.autocomplete(query, limit: 15)
        render json: results
      end

      def validate
        drug_name = params[:name]

        if drug_name.blank?
          render json: { valid: false }
          return
        end

        valid = RxNormService.validate_drug(drug_name)
        render json: { valid: valid, name: drug_name }
      end
    end
  end
end
