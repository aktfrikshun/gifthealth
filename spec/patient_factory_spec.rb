# frozen_string_literal: true

require "spec_helper"
require "set"

RSpec.describe "Patient Factory" do
  describe "basic factory" do
    it "creates a patient with random name" do
      patient = build(:patient)

      expect(patient).to be_a(Patient)
      expect(patient.name).to be_a(String)
      expect(patient.name).not_to be_empty
      expect(patient.total_fills).to eq(0)
      expect(patient.total_income).to eq(0)
    end
  end

  describe ":with_prescriptions trait" do
    it "creates a patient with multiple prescriptions" do
      patient = build(:patient, :with_prescriptions, prescription_count: 3)

      expect(patient.prescriptions.length).to eq(3)
      expect(patient.prescriptions.all?(&:created?)).to be true
    end

    it "allows custom prescription traits" do
      patient = build(:patient, :with_prescriptions, prescription_count: 2, prescription_traits: [:filled])

      expect(patient.prescriptions.length).to eq(2)
      expect(patient.prescriptions.all? { |p| p.net_fills == 1 }).to be true
      expect(patient.total_fills).to eq(2)
      expect(patient.total_income).to eq(10) # 2 prescriptions * 1 fill * $5
    end
  end

  describe ":with_filled_prescriptions trait" do
    it "creates a patient with filled prescriptions" do
      patient = build(:patient, :with_filled_prescriptions, prescription_count: 2, fill_count: 3)

      expect(patient.prescriptions.length).to eq(2)
      expect(patient.total_fills).to eq(6) # 2 prescriptions * 3 fills
      expect(patient.total_income).to eq(30) # 6 fills * $5
    end
  end

  describe "property-based testing with random data" do
    it "correctly aggregates income across multiple prescriptions" do
      5.times do
        prescription_count = rand(2..5)
        fill_count = rand(1..3)
        patient = build(:patient)
        
        # Manually create prescriptions with unique drug names
        used_drug_names = Set.new
        prescription_count.times do
          drug_name = loop do
            name = Faker::Alphanumeric.alphanumeric(number: 1, min_alpha: 1).upcase
            break name unless used_drug_names.include?(name)
          end
          used_drug_names.add(drug_name)
          prescription = build(:prescription, :with_fills, patient_name: patient.name, drug_name: drug_name, fill_count: fill_count)
          patient.instance_variable_get(:@prescriptions)[drug_name] = prescription
        end

        expected_fills = prescription_count * fill_count
        expected_income = expected_fills * 5

        expect(patient.total_fills).to eq(expected_fills)
        expect(patient.total_income).to eq(expected_income)
      end
    end

    it "handles patients with mixed prescription states" do
      patient = build(:patient)
      
      # Manually add prescriptions with different states
      prescription1 = build(:prescription, :created, patient_name: patient.name, drug_name: "A")
      prescription1.fill
      prescription1.fill
      
      prescription2 = build(:prescription, :created, patient_name: patient.name, drug_name: "B")
      prescription2.fill
      prescription2.return_fill
      
      prescription3 = build(:prescription, :created, patient_name: patient.name, drug_name: "C")
      
      patient.instance_variable_get(:@prescriptions)["A"] = prescription1
      patient.instance_variable_get(:@prescriptions)["B"] = prescription2
      patient.instance_variable_get(:@prescriptions)["C"] = prescription3

      expect(patient.total_fills).to eq(2) # 2 from A, 0 from B, 0 from C
      expect(patient.total_income).to eq(9) # (2*5) + (0*5 - 1*1) + 0 = 10 - 1 = 9
    end
  end
end

