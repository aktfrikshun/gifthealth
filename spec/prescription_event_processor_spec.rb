# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PrescriptionEventProcessor do
  let(:processor) { PrescriptionEventProcessor.new }

  describe '#process_event' do
    it 'handles created events' do
      processor.process_event(patient_name: 'John', drug_name: 'A', event_name: 'created')
      report = processor.generate_report
      expect(report).to include('John: 0 fills $0 income')
    end

    it 'ignores filled events before created' do
      processor.process_event(patient_name: 'John', drug_name: 'A', event_name: 'filled')
      report = processor.generate_report
      # Patient should not appear in report since no prescriptions were created
      expect(report).to be_empty
    end

    it 'ignores returned events before created' do
      processor.process_event(patient_name: 'John', drug_name: 'A', event_name: 'returned')
      report = processor.generate_report
      # Patient should not appear in report since no prescriptions were created
      expect(report).to be_empty
    end

    it 'processes filled events after created' do
      processor.process_event(patient_name: 'John', drug_name: 'A', event_name: 'created')
      processor.process_event(patient_name: 'John', drug_name: 'A', event_name: 'filled')
      report = processor.generate_report
      expect(report).to include('John: 1 fills $5 income')
    end

    it 'processes returned events after filled' do
      processor.process_event(patient_name: 'John', drug_name: 'A', event_name: 'created')
      processor.process_event(patient_name: 'John', drug_name: 'A', event_name: 'filled')
      processor.process_event(patient_name: 'John', drug_name: 'A', event_name: 'returned')
      report = processor.generate_report
      # 1 fill, 1 return: net_fills = 0, return_count = 1, income = 0*5 - 1*1 = -1
      expect(report).to include('John: 0 fills -$1 income')
    end
  end

  describe '#process_line' do
    it 'parses valid lines correctly' do
      processor.process_line('John A created')
      processor.process_line('John A filled')
      report = processor.generate_report
      expect(report).to include('John: 1 fills $5 income')
    end

    it 'skips empty lines' do
      processor.process_line('')
      processor.process_line('   ')
      report = processor.generate_report
      expect(report).to be_empty
    end

    it 'aborts with error message for invalid non-empty lines' do
      expect { processor.process_line('only one') }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
      expect { processor.process_line('only two') }.to raise_error(SystemExit)
      expect { processor.process_line('one two three four') }.to raise_error(SystemExit)
    end

    it 'handles lines with extra whitespace' do
      processor.process_line('  John   A   created  ')
      processor.process_line('John A filled')
      report = processor.generate_report
      expect(report).to include('John: 1 fills $5 income')
    end
  end

  describe '#generate_report' do
    it 'sorts patients alphabetically' do
      processor.process_line('Zebra A created')
      processor.process_line('Alice B created')
      processor.process_line('Bob C created')
      report = processor.generate_report
      expect(report[0]).to include('Alice')
      expect(report[1]).to include('Bob')
      expect(report[2]).to include('Zebra')
    end

    it 'matches expected output format from requirements' do
      input = [
        'Nick A created',
        'Mark B created',
        'Mark B filled',
        'Mark C filled',
        'Mark B returned',
        'John E created',
        'Mark B filled',
        'Mark B filled',
        'Paul D filled',
        'John E filled',
        'John E returned'
      ]

      input.each { |line| processor.process_line(line) }
      report = processor.generate_report

      expect(report).to include('John: 0 fills -$1 income')
      expect(report).to include('Mark: 2 fills $9 income')
      expect(report).to include('Nick: 0 fills $0 income')
    end

    it 'handles multiple prescriptions per patient' do
      processor.process_line('John A created')
      processor.process_line('John A filled')
      processor.process_line('John B created')
      processor.process_line('John B filled')
      processor.process_line('John B filled')
      report = processor.generate_report
      expect(report).to include('John: 3 fills $15 income')
    end

    it 'handles returns correctly with income calculation' do
      processor.process_line('John A created')
      processor.process_line('John A filled')
      processor.process_line('John A returned')
      processor.process_line('John A filled')
      processor.process_line('John A returned')
      report = processor.generate_report
      # 2 fills, 2 returns: net_fills = 0, return_count = 2, income = 0*5 - 2*1 = -2
      expect(report).to include('John: 0 fills -$2 income')
    end
  end
end
