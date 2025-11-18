# frozen_string_literal: true

require 'spec_helper'
require 'benchmark'

RSpec.describe 'Performance and Load Testing' do
  describe 'processing 1000 events' do
    it 'processes events and generates report within reasonable time' do
      processor = PrescriptionEventProcessor.new
      events = []

      # Generate 1000 events using FactoryBot
      puts "\nGenerating 1000 events..."
      generation_time = Benchmark.realtime do
        1000.times do
          patient = build(:patient)
          drug = Faker::Alphanumeric.alphanumeric(number: 1, min_alpha: 1).upcase

          # Create a realistic event sequence
          event_type = case rand(100)
                       when 0..30
                         'created'
                       when 31..85
                         'filled'
                       else
                         'returned'
                       end

          events << "#{patient.name} #{drug} #{event_type}"
        end
      end

      puts "Event generation: #{format('%.4f', generation_time)} seconds"

      # Time the processing
      processing_time = Benchmark.realtime do
        events.each do |event_line|
          processor.process_line(event_line)
        end
      end

      puts "Event processing: #{format('%.4f', processing_time)} seconds"

      # Time the report generation
      report_time = Benchmark.realtime do
        report = processor.generate_report
        report_lines = report.length
        puts "Report generated: #{report_lines} patients"
      end

      puts "Report generation: #{format('%.4f', report_time)} seconds"
      total_time = generation_time + processing_time + report_time
      puts "Total time: #{format('%.4f', total_time)} seconds"
      puts "Events per second: #{format('%.2f', 1000 / processing_time)}"
      puts

      # Performance assertions - these are generous thresholds
      expect(processing_time).to be < 1.0 # Should process 1000 events in under 1 second
      expect(report_time).to be < 0.5 # Should generate report in under 0.5 seconds
      expect(total_time).to be < 2.0 # Total should be under 2 seconds
    end

    it 'handles realistic prescription lifecycle patterns' do
      processor = PrescriptionEventProcessor.new
      events = []

      puts "\nGenerating realistic prescription lifecycle events..."
      generation_time = Benchmark.realtime do
        # Create 200 patients with realistic prescription patterns
        200.times do
          patient = build(:patient)

          # Each patient gets 1-5 prescriptions
          prescription_count = rand(1..5)
          prescription_count.times do
            drug = Faker::Alphanumeric.alphanumeric(number: 1, min_alpha: 1).upcase

            # Realistic pattern: created -> filled (multiple) -> sometimes returned
            events << "#{patient.name} #{drug} created"

            fill_count = rand(1..4)
            fill_count.times do
              events << "#{patient.name} #{drug} filled"
            end

            # 30% chance of returns
            next unless rand < 0.3

            return_count = rand(1..[fill_count, 2].min)
            return_count.times do
              events << "#{patient.name} #{drug} returned"
            end
          end
        end
      end

      event_count = events.length
      puts "Generated #{event_count} events in #{format('%.4f', generation_time)} seconds"

      processing_time = Benchmark.realtime do
        events.each do |event_line|
          processor.process_line(event_line)
        end
      end

      puts "Processed #{event_count} events in #{format('%.4f', processing_time)} seconds"
      puts "Events per second: #{format('%.2f', event_count / processing_time)}"

      report_time = Benchmark.realtime do
        report = processor.generate_report
        puts "Report: #{report.length} patients"
      end

      puts "Report generation: #{format('%.4f', report_time)} seconds"
      puts

      # Verify correctness
      report = processor.generate_report
      expect(report).not_to be_empty
      expect(report.length).to be <= 200 # Should have at most 200 patients

      # Performance check
      expect(processing_time).to be < 2.0
    end
  end
end
