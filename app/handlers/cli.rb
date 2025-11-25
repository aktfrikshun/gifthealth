# frozen_string_literal: true

require_relative '../services/prescription_event_processor'

# Command-line interface for the prescription event processor
class CLI
  # Entry point for the CLI application
  #
  # This class method provides a convenient way to start the CLI application.
  # It creates a new CLI instance and calls the instance run method, following
  # the common Ruby pattern of using class methods as entry points while keeping
  # the actual logic in instance methods for better testability.
  #
  # @param args [Array<String>] Command-line arguments (typically ARGV)
  def self.run(args)
    new.run(args)
  end

  # Runs the main CLI processing loop
  #
  # This method orchestrates the entire processing workflow:
  # 1. Determines the input source (stdin or file) based on command-line arguments
  # 2. Creates a new event processor to handle the events
  # 3. Processes each line of input sequentially
  # 4. Generates and prints the final report to stdout
  #
  # This design separates concerns: the CLI handles I/O and orchestration, while
  # the PrescriptionEventProcessor handles the business logic.
  #
  # @param args [Array<String>] Command-line arguments (empty array for stdin, filename for file input)
  def run(args)
    input_source = determine_input_source(args)
    processor = PrescriptionEventProcessor.new

    # Process each line of input, building up the patient and prescription data
    input_source.each_line do |line|
      processor.process_line(line)
    end

    # Generate and output the report to stdout
    processor.generate_report.each do |line|
      puts line
    end
  end

  private

  # Determines the input source based on command-line arguments
  #
  # This method implements the input source selection logic:
  # - If no arguments are provided, read from stdin (allows piping and interactive input)
  # - If a filename is provided, open that file for reading
  # - If the file doesn't exist, print an error and exit with status code 1
  #
  # The early return pattern ensures that stdin is returned immediately when no
  # arguments are provided, making the code clearer and avoiding unnecessary
  # variable assignments. The rescue block handles file not found errors gracefully
  # with a user-friendly error message.
  #
  # @param args [Array<String>] Command-line arguments
  # @return [IO, File] $stdin if no arguments, or a File object for the specified filename
  # @raise [SystemExit] if the specified file doesn't exist (via exit 1)
  def determine_input_source(args)
    # If no filename provided, read from standard input (allows piping)
    return $stdin if args.empty?

    # Attempt to open the specified file
    filename = args.first
    File.open(filename, 'r')
  rescue Errno::ENOENT
    # File not found - provide clear error message and exit gracefully
    warn "Error: File '#{filename}' not found"
    exit 1
  end
end
