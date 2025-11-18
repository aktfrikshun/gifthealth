# frozen_string_literal: true

require_relative "../services/prescription_event_processor"

# Command-line interface for the prescription event processor
class CLI
  def self.run(args)
    new.run(args)
  end

  def run(args)
    input_source = determine_input_source(args)
    processor = PrescriptionEventProcessor.new

    input_source.each_line do |line|
      processor.process_line(line)
    end

    processor.generate_report.each do |line|
      puts line
    end
  end

  private

  def determine_input_source(args)
    if args.empty?
      $stdin
    else
      filename = args.first
      File.open(filename, "r")
    end
  rescue Errno::ENOENT
    $stderr.puts "Error: File '#{filename}' not found"
    exit 1
  end
end

