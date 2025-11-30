# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Patient do
  let(:patient) { create(:patient, name: 'John') }

  describe '#get_or_create_prescription' do
    it "creates a new prescription if it doesn't exist" do
      prescription = patient.get_or_create_prescription('A')
      expect(prescription).to be_a(Prescription)
      expect(prescription.drug_name).to eq('A')
      expect(prescription.patient_name).to eq('John')
      expect(prescription).to be_persisted
    end

    it 'returns the same prescription for the same drug' do
      prescription1 = patient.get_or_create_prescription('A')
      prescription2 = patient.get_or_create_prescription('A')
      expect(prescription1.id).to eq(prescription2.id)
    end

    it 'creates different prescriptions for different drugs' do
      prescription1 = patient.get_or_create_prescription('A')
      prescription2 = patient.get_or_create_prescription('B')
      expect(prescription1.id).not_to eq(prescription2.id)
    end
  end

  describe '#total_fills' do
    it 'returns 0 for patient with no prescriptions' do
      expect(patient.total_fills).to eq(0)
    end

    it 'sums fills across all prescriptions' do
      prescription1 = patient.get_or_create_prescription('A')
      prescription1.mark_created
      prescription1.fill
      prescription1.fill

      prescription2 = patient.get_or_create_prescription('B')
      prescription2.mark_created
      prescription2.fill
      prescription2.return_fill

      patient.reload
      expect(patient.total_fills).to eq(2) # 2 from A, 0 from B
    end
  end

  describe '#total_income' do
    it 'returns 0 for patient with no prescriptions' do
      expect(patient.total_income).to eq(0)
    end

    it 'sums income across all prescriptions' do
      prescription1 = patient.get_or_create_prescription('A')
      prescription1.mark_created
      prescription1.fill # net_fills=1, income = 1*5 - 0*1 = 5

      prescription2 = patient.get_or_create_prescription('B')
      prescription2.mark_created
      prescription2.fill # net_fills=1
      prescription2.return_fill # net_fills=0, return_count=1, income = 0*5 - 1*1 = -1

      patient.reload
      expect(patient.total_income).to eq(4) # 5 + (-1) = 4
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      patient = Patient.new(name: nil)
      expect(patient).not_to be_valid
      expect(patient.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of name' do
      create(:patient, name: 'John')
      patient = Patient.new(name: 'John')
      expect(patient).not_to be_valid
      expect(patient.errors[:name]).to include('has already been taken')
    end
  end

  describe 'relationships' do
    it 'has many prescriptions' do
      expect(patient.prescriptions).to be_empty
      expect(patient.prescription_count).to eq(0)

      prescription1 = patient.get_or_create_prescription('A')
      prescription2 = patient.get_or_create_prescription('B')

      patient.reload
      expect(patient.prescriptions.length).to eq(2)
      expect(patient.prescription_count).to eq(2)
      expect(patient.prescriptions).to include(prescription1, prescription2)
    end
  end
end
