# frozen_string_literal: true

require_relative 'prescription'

# Tracks all prescriptions and aggregate statistics for a patient
# Has many Prescriptions (has_many :prescriptions)
class Patient
  attr_reader :name

  # Initializes a new Patient instance
  #
  # This method sets up a patient with their name and initializes an empty hash
  # to store prescriptions keyed by drug name. It validates that the name is not
  # nil or empty to ensure data integrity.
  #
  # @param name [String] The name of the patient
  # @raise [ArgumentError] if name is nil or empty
  def initialize(name)
    validate_name!(name)
    @name = name
    @prescriptions = {}
  end

  # Returns all prescriptions associated with this patient
  #
  # This method implements the "has many prescriptions" relationship by returning
  # an array of all prescription objects. The prescriptions are stored internally
  # in a hash keyed by drug name for efficient lookup, but this method provides
  # a clean array interface for iteration and aggregation operations.
  #
  # @return [Array<Prescription>] An array of all prescriptions for this patient
  def prescriptions
    @prescriptions.values
  end

  # Gets an existing prescription or creates a new one for the given drug
  #
  # This method implements a lazy initialization pattern for prescriptions. If a
  # prescription for the given drug already exists, it returns that prescription.
  # Otherwise, it creates a new Prescription instance associated with this patient
  # and stores it in the prescriptions hash. This ensures that each patient has
  # at most one prescription per drug name, which is the correct business model.
  #
  # @param drug_name [String] The name of the drug to get or create a prescription for
  # @return [Prescription] The existing or newly created prescription
  def get_or_create_prescription(drug_name)
    @prescriptions[drug_name] ||= Prescription.new(
      patient: self,
      drug_name: drug_name
    )
  end

  # Adds a prescription to this patient's collection
  #
  # This method allows external code to add a prescription that was created elsewhere.
  # It validates that the prescription actually belongs to this patient before adding it,
  # ensuring data integrity and preventing prescription-patient mismatches. This is
  # important for maintaining the relationship integrity between Patient and Prescription.
  #
  # @param prescription [Prescription] The prescription to add
  # @raise [ArgumentError] if the prescription's patient doesn't match this patient
  def add_prescription(prescription)
    validate_prescription_belongs_to_patient!(prescription)
    @prescriptions[prescription.drug_name] = prescription
  end

  # Calculates the total number of net fills across all prescriptions
  #
  # This method aggregates the net fills (fills minus returns) from all prescriptions
  # for this patient. It's used in reporting to show the total number of successful
  # fills across all drugs for a patient.
  #
  # @return [Integer] The sum of net_fills across all prescriptions
  def total_fills
    @prescriptions.values.sum(&:net_fills)
  end

  # Calculates the total income across all prescriptions
  #
  # This method aggregates the income from all prescriptions for this patient.
  # It sums up the income (which can be negative if returns exceed fills) from
  # each prescription to provide the patient's total financial impact.
  #
  # @return [Integer] The sum of income across all prescriptions
  def total_income
    @prescriptions.values.sum(&:income)
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
    @prescriptions.values.any?(&:created?)
  end

  # Returns the count of unique prescriptions (by drug name) for this patient
  #
  # This method provides a simple count of how many different drugs this patient
  # has prescriptions for. Since prescriptions are stored in a hash keyed by drug
  # name, the size of the hash gives us the unique prescription count.
  #
  # @return [Integer] The number of unique prescriptions (drugs) for this patient
  def prescription_count
    @prescriptions.size
  end

  private

  # Validates that the name parameter is valid
  #
  # This method ensures that the patient name is not nil and not an empty string
  # (after stripping whitespace). This prevents patients with invalid names from
  # being created, maintaining data quality and ensuring meaningful patient identification.
  #
  # @param name [Object] The name to validate
  # @raise [ArgumentError] if name is nil or empty
  def validate_name!(name)
    raise ArgumentError, 'name cannot be nil' if name.nil?
    raise ArgumentError, 'name cannot be empty' if name.to_s.strip.empty?
  end

  # Validates that a prescription belongs to this patient
  #
  # This method ensures referential integrity by checking that the prescription's
  # patient reference matches this patient instance. This prevents accidentally
  # associating a prescription with the wrong patient, which would corrupt the
  # data model and lead to incorrect reporting.
  #
  # @param prescription [Prescription] The prescription to validate
  # @raise [ArgumentError] if the prescription's patient doesn't match this patient
  def validate_prescription_belongs_to_patient!(prescription)
    return if prescription.patient == self

    raise ArgumentError, "Prescription patient '#{prescription.patient.name}' does not match Patient name '#{@name}'"
  end
end
