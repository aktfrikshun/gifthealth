# frozen_string_literal: true

# Processes prescription events and generates reports
class PrescriptionEventProcessor
  # Processes a single prescription event
  #
  # This method is the core event processing logic. It takes event details and
  # applies them to the appropriate patient and prescription. It uses lazy initialization
  # to create patients and prescriptions as needed, ensuring that the data model is
  # built incrementally as events are processed. The case statement routes different
  # event types to their corresponding prescription methods, enforcing business rules
  # at the model level.
  #
  # @param patient_name [String] The name of the patient
  # @param drug_name [String] The name of the drug
  # @param event_name [String] The type of event ('created', 'filled', or 'returned')
  def process_event(patient_name:, drug_name:, event_name:)
    patient = Patient.find_or_create_by!(name: patient_name)
    prescription = patient.get_or_create_prescription(drug_name)

    # Route the event to the appropriate prescription method based on event type
    # Unknown event types are silently ignored to allow for future extensibility
    case event_name
    when 'created'
      prescription.mark_created
    when 'filled'
      prescription.fill
    when 'returned'
      prescription.return_fill
    else
      # Unknown event type - ignore
    end
  end

  # Processes a single line of input text
  #
  # This method parses a line of space-delimited input and processes it as an event.
  # It handles empty lines gracefully by skipping them, and validates that the input
  # has exactly three parts (patient name, drug name, event name). If the format is
  # invalid, it aborts the program with a clear error message to help users identify
  # problematic input lines.
  #
  # @param line [String] A line of input containing "PatientName DrugName EventName"
  # @raise [SystemExit] if the input format is invalid (via abort)
  def process_line(line)
    stripped_line = line.strip
    # Skip empty lines to handle trailing newlines and blank lines in input files
    return if stripped_line.empty?

    # Split on whitespace (one or more spaces/tabs) to handle variable spacing
    parts = stripped_line.split(/\s+/)

    # Validate that we have exactly three parts (patient, drug, event)
    # This ensures the input matches the expected format before processing
    unless parts.length == 3
      abort "Error: Invalid input format. Expected 'PatientName DrugName EventName', got: #{line.inspect}"
    end

    patient_name, drug_name, event_name = parts
    process_event(
      patient_name: patient_name,
      drug_name: drug_name,
      event_name: event_name
    )
  end

  # Generates a formatted report of all patients with created prescriptions
  #
  # This method creates the final output report by:
  # 1. Filtering to only patients who have at least one created prescription
  # 2. Sorting by total fills (descending), then by total income (ascending)
  # 3. Formatting each patient's data into a readable string
  #
  # The sorting logic uses a negative sign on total_fills to achieve descending order,
  # then sorts by income ascending as a secondary sort. This matches the observed
  # expected output format from sample data.
  #
  # @return [Array<String>] An array of formatted report lines, one per patient
  def generate_report
    Patient.all
           .select(&:has_created_prescriptions?)
           .sort_by { |patient| [-patient.total_fills, patient.total_income] }
           .map { |patient| format_report_line(patient) }
  end

  private

  # Formats a single patient's data into a report line
  #
  # This method creates a human-readable string representation of a patient's
  # prescription statistics. It formats the income with a dollar sign, handling
  # negative values by prefixing with a minus sign and using the absolute value
  # for display. The format matches the expected output: "PatientName: X fills $Y income"
  #
  # @param patient [Patient] The patient to format
  # @return [String] A formatted string with patient name, fill count, and income
  def format_report_line(patient)
    fills = patient.total_fills
    income = patient.total_income
    # Format income with proper sign handling for negative values
    income_str = income >= 0 ? "$#{income}" : "-$#{income.abs}"
    "#{patient.name}: #{fills} fills #{income_str} income"
  end
end

