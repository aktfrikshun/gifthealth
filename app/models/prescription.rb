# frozen_string_literal: true

# Represents a single prescription and tracks its state
# Belongs to a Patient (has_one patient)
class Prescription
  attr_reader :patient, :drug_name

  def initialize(patient:, drug_name:)
    validate_patient!(patient)
    validate_drug_name!(drug_name)

    @patient = patient
    @drug_name = drug_name
    @created = false
    @fill_count = 0
    @return_count = 0
  end

  def patient_name
    @patient.name
  end

  def created?
    @created
  end

  def mark_created
    @created = true
  end

  def fill
    return false unless @created

    @fill_count += 1
    true
  end

  def return_fill
    return false unless @created
    return false if @fill_count <= @return_count

    @return_count += 1
    true
  end

  def net_fills
    @fill_count - @return_count
  end

  def income
    # Each fill gives $5, but returns cancel the income from the fill AND cost $1
    # So: (net_fills * 5) - (return_count * 1)
    # This means: (fill_count - return_count) * 5 - return_count * 1
    # Which simplifies to: fill_count * 5 - return_count * 6
    (net_fills * 5) - (@return_count * 1)
  end

  private

  def validate_patient!(patient)
    raise ArgumentError, 'patient cannot be nil' if patient.nil?
    raise ArgumentError, 'patient must be an instance of Patient' unless patient.is_a?(Patient)
  end

  def validate_drug_name!(drug_name)
    raise ArgumentError, 'drug_name cannot be nil' if drug_name.nil?
    raise ArgumentError, 'drug_name cannot be empty' if drug_name.to_s.strip.empty?
  end
end
