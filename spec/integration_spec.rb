# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'Integration tests', type: :integration do
  let(:executable) { File.join(__dir__, '..', 'bin', 'prescription_processor') }

  # Ensure database is cleaned before each test since we're calling external process
  before(:each) do
    Patient.destroy_all
    Prescription.destroy_all
  end

  describe 'sample input from requirements' do
    let(:input) do
      <<~INPUT
        Nick A created
        Mark B created
        Mark B filled
        Mark C filled
        Mark B returned
        John E created
        Mark B filled
        Mark B filled
        Paul D filled
        John E filled
        John E returned
      INPUT
    end

    it 'produces expected output' do
      file = Tempfile.new('test_input')
      file.write(input)
      file.close

      stdout, stderr, status = Open3.capture3('ruby', executable, file.path)

      expect(status.success?).to be true
      expect(stderr).to be_empty

      output_lines = stdout.strip.split("\n")
      expect(output_lines).to include('John: 0 fills -$1 income')
      expect(output_lines).to include('Mark: 2 fills $9 income')
      expect(output_lines).to include('Nick: 0 fills $0 income')

      file.unlink
    end
  end

  describe 'stdin input' do
    it 'processes input from stdin' do
      input = "John A created\nJohn A filled\n"
      stdout, stderr, status = Open3.capture3('ruby', executable, stdin_data: input)

      expect(status.success?).to be true
      expect(stderr).to be_empty
      expect(stdout.strip).to eq('John: 1 fills $5 income')
    end
  end
end
