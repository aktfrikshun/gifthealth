# frozen_string_literal: true

require 'spec_helper'
require_relative '../../config/environment'

RSpec.describe 'CRUD Operations', type: :feature do
  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end

  describe 'Prescription CRUD' do
    it 'creates a new prescription' do
      patient = Patient.create!(name: 'John Doe')

      prescription = patient.prescriptions.create!(
        drug_name: 'Aspirin',
        created: true,
        fill_count: 2,
        return_count: 0
      )

      expect(prescription).to be_persisted
      expect(prescription.drug_name).to eq('Aspirin')
      expect(prescription.net_fills).to eq(2)
      expect(prescription.income).to eq(10)
    end

    it 'updates a prescription' do
      patient = Patient.create!(name: 'Jane Smith')
      prescription = patient.prescriptions.create!(
        drug_name: 'Ibuprofen',
        created: true,
        fill_count: 1,
        return_count: 0
      )

      prescription.update!(fill_count: 3)

      expect(prescription.fill_count).to eq(3)
      expect(prescription.net_fills).to eq(3)
      expect(prescription.income).to eq(15)
    end

    it 'deletes a prescription' do
      patient = Patient.create!(name: 'Bob Johnson')
      prescription = patient.prescriptions.create!(
        drug_name: 'Tylenol',
        created: true,
        fill_count: 1,
        return_count: 0
      )

      prescription_id = prescription.id
      prescription.destroy

      expect(Prescription.find_by(id: prescription_id)).to be_nil
    end

    it 'increments fill count' do
      patient = Patient.create!(name: 'Alice Brown')
      prescription = patient.prescriptions.create!(
        drug_name: 'Advil',
        created: true,
        fill_count: 1,
        return_count: 0
      )

      prescription.fill

      expect(prescription.fill_count).to eq(2)
    end

    it 'decrements fill count (return)' do
      patient = Patient.create!(name: 'Charlie Wilson')
      prescription = patient.prescriptions.create!(
        drug_name: 'Motrin',
        created: true,
        fill_count: 3,
        return_count: 1
      )

      prescription.return_fill

      expect(prescription.return_count).to eq(2)
      expect(prescription.net_fills).to eq(1)
    end
  end

  describe 'Patient CRUD' do
    it 'creates a patient' do
      patient = Patient.create!(name: 'New Patient')

      expect(patient).to be_persisted
      expect(patient.name).to eq('New Patient')
    end

    it 'lists all patients' do
      Patient.create!(name: 'Patient 1')
      Patient.create!(name: 'Patient 2')
      Patient.create!(name: 'Patient 3')

      expect(Patient.count).to eq(3)
    end

    it 'deletes a patient and their prescriptions' do
      patient = Patient.create!(name: 'Delete Me')
      patient.prescriptions.create!(drug_name: 'Drug A', created: true)
      patient.prescriptions.create!(drug_name: 'Drug B', created: true)

      patient_id = patient.id
      patient.destroy

      expect(Patient.find_by(id: patient_id)).to be_nil
      expect(Prescription.where(patient_id: patient_id).count).to eq(0)
    end

    it 'clears all prescriptions for a patient' do
      patient = Patient.create!(name: 'Clear My Prescriptions')
      patient.prescriptions.create!(drug_name: 'Drug A', created: true)
      patient.prescriptions.create!(drug_name: 'Drug B', created: true)

      patient.prescriptions.destroy_all

      expect(patient.prescriptions.count).to eq(0)
      expect(Patient.find(patient.id)).to eq(patient)
    end
  end

  describe 'Prescription income calculations' do
    it 'calculates correct income for fills only' do
      patient = Patient.create!(name: 'Test Patient')
      prescription = patient.prescriptions.create!(
        drug_name: 'Test Drug',
        created: true,
        fill_count: 5,
        return_count: 0
      )

      expect(prescription.income).to eq(25) # 5 fills * $5 = $25
    end

    it 'calculates correct income with returns' do
      patient = Patient.create!(name: 'Test Patient')
      prescription = patient.prescriptions.create!(
        drug_name: 'Test Drug',
        created: true,
        fill_count: 10,
        return_count: 3
      )

      expect(prescription.net_fills).to eq(7)
      # Income = (net_fills * 5) - (return_count * 1)
      # Income = (7 * 5) - (3 * 1) = 35 - 3 = 32
      expect(prescription.income).to eq(32)
    end

    it 'calculates income even for non-created prescriptions' do
      patient = Patient.create!(name: 'Test Patient')
      prescription = patient.prescriptions.create!(
        drug_name: 'Test Drug',
        created: false,
        fill_count: 5,
        return_count: 0
      )

      # Income is calculated regardless of created status
      # but prescriptions not created won't appear in reports
      expect(prescription.income).to eq(25)
    end
  end

  describe 'Patient aggregations' do
    it 'calculates total fills across all prescriptions' do
      patient = Patient.create!(name: 'Multi Rx Patient')
      patient.prescriptions.create!(drug_name: 'Drug A', created: true, fill_count: 3, return_count: 1)
      patient.prescriptions.create!(drug_name: 'Drug B', created: true, fill_count: 5, return_count: 0)
      patient.prescriptions.create!(drug_name: 'Drug C', created: true, fill_count: 2, return_count: 1)

      # Total fills = sum of all net_fills = (3-1) + (5-0) + (2-1) = 2 + 5 + 1 = 8
      expect(patient.total_fills).to eq(8)
    end

    it 'calculates total income across all prescriptions' do
      patient = Patient.create!(name: 'Multi Rx Patient')
      patient.prescriptions.create!(drug_name: 'Drug A', created: true, fill_count: 3, return_count: 1)
      patient.prescriptions.create!(drug_name: 'Drug B', created: true, fill_count: 5, return_count: 0)

      # Income = Drug A: (3-1)*5 - 1*1 = 10 - 1 = 9
      # Income = Drug B: (5-0)*5 - 0*1 = 25
      # Total = 9 + 25 = 34
      expect(patient.total_income).to eq(34)
    end
  end
end
