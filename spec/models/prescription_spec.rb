# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prescription do
  let(:patient) { create(:patient, name: 'John') }
  let(:prescription) { create(:prescription, patient: patient, drug_name: 'A') }

  describe '#created?' do
    it 'returns false initially' do
      expect(prescription.created?).to be false
    end

    it 'returns true after marking as created' do
      prescription.mark_created
      prescription.reload
      expect(prescription.created?).to be true
    end
  end

  describe '#fill' do
    it 'returns nil if prescription is not created' do
      expect(prescription.fill).to be_nil
      prescription.reload
      expect(prescription.net_fills).to eq(0)
    end

    it 'increments fill count after creation' do
      prescription.mark_created
      result = prescription.fill
      expect(result).to eq(prescription)
      prescription.reload
      expect(prescription.net_fills).to eq(1)
    end

    it 'allows multiple fills' do
      prescription.mark_created
      prescription.fill
      prescription.fill
      prescription.reload
      expect(prescription.net_fills).to eq(2)
    end
  end

  describe '#return_fill' do
    it 'returns nil if prescription is not created' do
      expect(prescription.return_fill).to be_nil
    end

    it 'returns nil if there are no fills to return' do
      prescription.mark_created
      expect(prescription.return_fill).to be_nil
    end

    it 'decrements net fills when returning' do
      prescription.mark_created
      prescription.fill
      prescription.fill
      result = prescription.return_fill
      expect(result).to eq(prescription)
      prescription.reload
      expect(prescription.net_fills).to eq(1)
    end

    it 'cannot return more than filled' do
      prescription.mark_created
      prescription.fill
      prescription.return_fill
      prescription.reload
      expect(prescription.return_fill).to be_nil
      expect(prescription.net_fills).to eq(0)
    end
  end

  describe '#income' do
    it 'returns 0 for uncreated prescription' do
      expect(prescription.income).to eq(0)
    end

    it 'returns $5 per net fill' do
      prescription.mark_created
      prescription.fill
      prescription.reload
      expect(prescription.income).to eq(5) # 1 net fill * 5 - 0 returns * 1
      prescription.fill
      prescription.reload
      expect(prescription.income).to eq(10) # 2 net fills * 5 - 0 returns * 1
    end

    it 'calculates income correctly with returns (return cancels fill income + $1 penalty)' do
      prescription.mark_created
      prescription.fill
      prescription.fill
      prescription.return_fill
      prescription.reload
      # 2 fills, 1 return: net_fills = 1, return_count = 1
      # income = net_fills * 5 - return_count * 1 = 1 * 5 - 1 * 1 = 4
      expect(prescription.income).to eq(4)
    end

    it 'calculates negative income correctly with multiple returns' do
      prescription.mark_created
      prescription.fill
      prescription.return_fill
      prescription.fill
      prescription.return_fill
      prescription.reload
      # 2 fills, 2 returns: net_fills = 0, return_count = 2
      # income = net_fills * 5 - return_count * 1 = 0 * 5 - 2 * 1 = -2
      expect(prescription.income).to eq(-2)
    end
  end

  describe 'validations' do
    it 'validates presence of patient' do
      prescription = Prescription.new(drug_name: 'A')
      expect(prescription).not_to be_valid
      expect(prescription.errors[:patient]).to include('must exist')
    end

    it 'validates presence of drug_name' do
      prescription = Prescription.new(patient: patient, drug_name: nil)
      expect(prescription).not_to be_valid
      expect(prescription.errors[:drug_name]).to include("can't be blank")
    end

    it 'validates uniqueness of drug_name scoped to patient' do
      create(:prescription, patient: patient, drug_name: 'A')
      prescription = Prescription.new(patient: patient, drug_name: 'A')
      expect(prescription).not_to be_valid
      expect(prescription.errors[:drug_name]).to include('has already been taken')
    end
  end

  describe 'relationships' do
    it 'belongs to a patient' do
      expect(prescription.patient).to eq(patient)
      expect(prescription.patient.name).to eq('John')
    end

    it 'returns patient_name from patient' do
      expect(prescription.patient_name).to eq('John')
    end
  end
end
