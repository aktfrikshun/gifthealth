# frozen_string_literal: true

require_relative "../models/patient"
require_relative "../models/prescription"

# Processes prescription events and generates reports
class PrescriptionEventProcessor
  def initialize
    @patients = {}
  end

  def process_event(patient_name:, drug_name:, event_name:)
    patient = get_or_create_patient(patient_name)
    prescription = patient.get_or_create_prescription(drug_name)

    case event_name
    when "created"
      prescription.mark_created
    when "filled"
      prescription.fill
    when "returned"
      prescription.return_fill
    else
      # Unknown event type - ignore
    end
  end

  def process_line(line)
    parts = line.strip.split(/\s+/, 3)
    return if parts.length != 3

    patient_name, drug_name, event_name = parts
    process_event(
      patient_name: patient_name,
      drug_name: drug_name,
      event_name: event_name
    )
  end

  def generate_report
    @patients.values
              .select(&:has_created_prescriptions?)
              .sort_by(&:name)
              .map { |patient| format_report_line(patient) }
  end

  private

  def get_or_create_patient(name)
    @patients[name] ||= Patient.new(name)
  end

  def format_report_line(patient)
    fills = patient.total_fills
    income = patient.total_income
    income_str = income >= 0 ? "$#{income}" : "-$#{income.abs}"
    "#{patient.name}: #{fills} fills #{income_str} income"
  end
end

