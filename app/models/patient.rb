# frozen_string_literal: true

require_relative "prescription"

# Tracks all prescriptions and aggregate statistics for a patient
# Has many Prescriptions (has_many :prescriptions)
class Patient
  attr_reader :name

  def initialize(name)
    validate_name!(name)
    @name = name
    @prescriptions = {}
  end

  # Has many prescriptions relationship
  def prescriptions
    @prescriptions.values
  end

  def get_or_create_prescription(drug_name)
    @prescriptions[drug_name] ||= Prescription.new(
      patient: self,
      drug_name: drug_name
    )
  end

  def add_prescription(prescription)
    validate_prescription_belongs_to_patient!(prescription)
    @prescriptions[prescription.drug_name] = prescription
  end

  def total_fills
    @prescriptions.values.sum(&:net_fills)
  end

  def total_income
    @prescriptions.values.sum(&:income)
  end

  def has_created_prescriptions?
    @prescriptions.values.any?(&:created?)
  end

  def prescription_count
    @prescriptions.size
  end

  private

  def validate_name!(name)
    raise ArgumentError, "name cannot be nil" if name.nil?
    raise ArgumentError, "name cannot be empty" if name.to_s.strip.empty?
  end

  def validate_prescription_belongs_to_patient!(prescription)
    unless prescription.patient == self
      raise ArgumentError, "Prescription patient '#{prescription.patient.name}' does not match Patient name '#{@name}'"
    end
  end
end
