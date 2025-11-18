# frozen_string_literal: true

# Tracks all prescriptions and aggregate statistics for a patient
class Patient
  attr_reader :name

  def initialize(name)
    @name = name
    @prescriptions = {}
  end

  def get_or_create_prescription(drug_name)
    @prescriptions[drug_name] ||= Prescription.new(
      patient_name: @name,
      drug_name: drug_name
    )
  end

  def total_fills
    @prescriptions.values.sum(&:net_fills)
  end

  def total_income
    @prescriptions.values.sum(&:income)
  end

  def prescriptions
    @prescriptions.values
  end

  def has_created_prescriptions?
    @prescriptions.values.any?(&:created?)
  end
end

