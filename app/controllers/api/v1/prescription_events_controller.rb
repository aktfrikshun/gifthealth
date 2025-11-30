# frozen_string_literal: true

module Api
  module V1
    class PrescriptionEventsController < ActionController::API
      # POST /api/v1/prescription_events
      def create
        unless params[:patient_name] && params[:drug_name] && params[:event_name]
          render json: { error: 'Missing required parameters: patient_name, drug_name, event_name' }, 
                 status: :bad_request
          return
        end

        begin
          processor = PrescriptionEventProcessor.new
          processor.process_event(
            patient_name: params[:patient_name],
            drug_name: params[:drug_name],
            event_name: params[:event_name]
          )

          render json: { 
            message: 'Event processed successfully',
            patient_name: params[:patient_name],
            drug_name: params[:drug_name],
            event_name: params[:event_name]
          }, status: :created
        rescue StandardError => e
          render json: { error: "Failed to process event: #{e.message}" }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/prescription_events/batch
      def batch
        unless params[:events].is_a?(Array)
          render json: { error: 'events must be an array' }, status: :bad_request
          return
        end

        begin
          processor = PrescriptionEventProcessor.new
          processed_count = 0
          errors = []

          params[:events].each_with_index do |event, index|
            unless event[:patient_name] && event[:drug_name] && event[:event_name]
              errors << { index: index, error: 'Missing required fields' }
              next
            end

            processor.process_event(
              patient_name: event[:patient_name],
              drug_name: event[:drug_name],
              event_name: event[:event_name]
            )
            processed_count += 1
          rescue StandardError => e
            errors << { index: index, error: e.message }
          end

          response_data = {
            processed: processed_count,
            total: params[:events].length
          }
          response_data[:errors] = errors if errors.any?

          render json: response_data, status: :ok
        rescue StandardError => e
          render json: { error: "Failed to process batch: #{e.message}" }, status: :unprocessable_entity
        end
      end
    end
  end
end
