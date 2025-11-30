# frozen_string_literal: true

# Tracks all prescriptions and aggregate statistics for a patient
# Has many Prescriptions (has_many :prescriptions)
class Patient < ApplicationRecord
  has_many :prescriptions, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  
  # Gets an existing prescription or creates a new one for the given drug
  #
  # This method implements a lazy initialization pattern for prescriptions. If a
  # prescription for the given drug already exists, it returns that prescription.
  # Otherwise, it creates a new Prescription instance associated with this patient
  # and stores it in the database. This ensures that each patient has at most one 
  # prescription per drug name, which is the correct business model.
  #
  # @param drug_name [String] The name of the drug to get or create a prescription for
  # @return [Prescription] The existing or newly created prescription
  def get_or_create_prescription(drug_name)
    prescriptions.find_or_create_by!(drug_name: drug_name)
  end

  # Calculates the total number of net fills across all prescriptions
  #
  # This method aggregates the net fills (fills minus returns) from all prescriptions
  # for this patient. It's used in reporting to show the total number of successful
  # fills across all drugs for a patient.
  #
  # @return [Integer] The sum of net_fills across all prescriptions
  def total_fills
    prescriptions.sum(&:net_fills)
  end

  # Calculates the total income across all prescriptions
  #
  # This method aggregates the income from all prescriptions for this patient.
  # It sums up the income (which can be negative if returns exceed fills) from
  # each prescription to provide the patient's total financial impact.
  #
  # @return [Integer] The sum of income across all prescriptions
  def total_income
    prescriptions.sum(&:income)
  end

  # Checks if this patient has any prescriptions that have been created
  #
  # This method is used to filter patients in reports. Only patients who have
  # at least one prescription that has been marked as 'created' should appear
  # in the output, as per business requirements. This prevents patients with
  # no actual prescriptions from appearing in reports.
  #
  # @return [Boolean] true if at least one prescription has been created, false otherwise
  def has_created_prescriptions?
    prescriptions.where(created: true).exists?
  end

  # Returns the count of unique prescriptions (by drug name) for this patient
  #
  # This method provides a simple count of how many different drugs this patient
  # has prescriptions for.
  #
  # @return [Integer] The number of unique prescriptions (drugs) for this patient
  def prescription_count
    prescriptions.count
  end
end

