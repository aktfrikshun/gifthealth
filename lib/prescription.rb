# frozen_string_literal: true

# Represents a single prescription and tracks its state
class Prescription
  attr_reader :patient_name, :drug_name

  def initialize(patient_name:, drug_name:)
    @patient_name = patient_name
    @drug_name = drug_name
    @created = false
    @fill_count = 0
    @return_count = 0
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
end

