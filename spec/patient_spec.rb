# frozen_string_literal: true

require "spec_helper"

RSpec.describe Patient do
  let(:patient) { Patient.new("John") }

  describe "#get_or_create_prescription" do
    it "creates a new prescription if it doesn't exist" do
      prescription = patient.get_or_create_prescription("A")
      expect(prescription).to be_a(Prescription)
      expect(prescription.drug_name).to eq("A")
      expect(prescription.patient_name).to eq("John")
    end

    it "returns the same prescription for the same drug" do
      prescription1 = patient.get_or_create_prescription("A")
      prescription2 = patient.get_or_create_prescription("A")
      expect(prescription1).to be(prescription2)
    end

    it "creates different prescriptions for different drugs" do
      prescription1 = patient.get_or_create_prescription("A")
      prescription2 = patient.get_or_create_prescription("B")
      expect(prescription1).not_to be(prescription2)
    end
  end

  describe "#total_fills" do
    it "returns 0 for patient with no prescriptions" do
      expect(patient.total_fills).to eq(0)
    end

    it "sums fills across all prescriptions" do
      prescription1 = patient.get_or_create_prescription("A")
      prescription1.mark_created
      prescription1.fill
      prescription1.fill

      prescription2 = patient.get_or_create_prescription("B")
      prescription2.mark_created
      prescription2.fill
      prescription2.return_fill

      expect(patient.total_fills).to eq(2) # 2 from A, 0 from B
    end
  end

  describe "#total_income" do
    it "returns 0 for patient with no prescriptions" do
      expect(patient.total_income).to eq(0)
    end

    it "sums income across all prescriptions" do
      prescription1 = patient.get_or_create_prescription("A")
      prescription1.mark_created
      prescription1.fill # net_fills=1, income = 1*5 - 0*1 = 5

      prescription2 = patient.get_or_create_prescription("B")
      prescription2.mark_created
      prescription2.fill # net_fills=1
      prescription2.return_fill # net_fills=0, return_count=1, income = 0*5 - 1*1 = -1

      expect(patient.total_income).to eq(4) # 5 + (-1) = 4
    end
  end

  describe "validations" do
    it "raises error when name is nil" do
      expect { Patient.new(nil) }.to raise_error(ArgumentError, "name cannot be nil")
    end

    it "raises error when name is empty" do
      expect { Patient.new("") }.to raise_error(ArgumentError, "name cannot be empty")
    end

    it "raises error when name is only whitespace" do
      expect { Patient.new("   ") }.to raise_error(ArgumentError, "name cannot be empty")
    end
  end

  describe "relationships" do
    it "has many prescriptions" do
      expect(patient.prescriptions).to be_empty
      expect(patient.prescription_count).to eq(0)

      prescription1 = patient.get_or_create_prescription("A")
      prescription2 = patient.get_or_create_prescription("B")

      expect(patient.prescriptions.length).to eq(2)
      expect(patient.prescription_count).to eq(2)
      expect(patient.prescriptions).to include(prescription1, prescription2)
    end

    it "validates prescription belongs to patient when adding" do
      other_patient = Patient.new("Jane")
      prescription = Prescription.new(patient: other_patient, drug_name: "A")

      expect { patient.add_prescription(prescription) }.to raise_error(
        ArgumentError,
        "Prescription patient 'Jane' does not match Patient name 'John'"
      )
    end

    it "allows adding prescription that belongs to patient" do
      prescription = Prescription.new(patient: patient, drug_name: "A")
      patient.add_prescription(prescription)

      expect(patient.prescriptions).to include(prescription)
      expect(patient.get_or_create_prescription("A")).to eq(prescription)
    end
  end
end

