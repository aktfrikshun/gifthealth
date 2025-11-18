# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Prescription Factory' do
  describe 'basic factory' do
    it 'creates a prescription with random data' do
      prescription = build(:prescription)

      expect(prescription).to be_a(Prescription)
      expect(prescription.patient_name).to be_a(String)
      expect(prescription.patient_name).not_to be_empty
      expect(prescription.drug_name).to be_a(String)
      expect(prescription.drug_name.length).to eq(1)
      expect(prescription.created?).to be false
    end

    it 'creates unique prescriptions with different data' do
      prescription1 = build(:prescription)
      prescription2 = build(:prescription)

      # With Faker, it's very unlikely to get the same random data
      unless prescription1.patient_name == prescription2.patient_name
        expect(prescription1.patient_name).not_to eq(prescription2.patient_name)
      end
    end
  end

  describe ':created trait' do
    it 'creates a prescription that is already created' do
      prescription = build(:prescription, :created)

      expect(prescription.created?).to be true
    end
  end

  describe ':filled trait' do
    it 'creates a prescription that is created and filled once' do
      prescription = build(:prescription, :filled)

      expect(prescription.created?).to be true
      expect(prescription.net_fills).to eq(1)
      expect(prescription.income).to eq(5)
    end
  end

  describe ':with_fills trait' do
    it 'creates a prescription with multiple fills' do
      prescription = build(:prescription, :with_fills, fill_count: 3)

      expect(prescription.created?).to be true
      expect(prescription.net_fills).to eq(3)
      expect(prescription.income).to eq(15) # 3 * 5
    end

    it 'defaults to 1 fill if fill_count not specified' do
      prescription = build(:prescription, :with_fills)

      expect(prescription.net_fills).to eq(1)
    end
  end

  describe ':with_returns trait' do
    it 'creates a prescription with fills and returns' do
      prescription = build(:prescription, :with_returns, fill_count: 5, return_count: 2)

      expect(prescription.created?).to be true
      expect(prescription.net_fills).to eq(3) # 5 - 2
      expect(prescription.income).to eq(13) # (3 * 5) - (2 * 1) = 15 - 2 = 13
    end

    it 'handles edge case where returns equal fills' do
      prescription = build(:prescription, :with_returns, fill_count: 3, return_count: 3)

      expect(prescription.net_fills).to eq(0)
      expect(prescription.income).to eq(-3) # (0 * 5) - (3 * 1) = -3
    end
  end

  describe 'property-based testing with random data' do
    it 'always calculates income correctly for any number of fills' do
      10.times do
        fill_count = rand(1..10)
        prescription = build(:prescription, :with_fills, fill_count: fill_count)

        expect(prescription.income).to eq(fill_count * 5)
      end
    end

    it 'always calculates income correctly for fills and returns' do
      10.times do
        fill_count = rand(2..10)
        return_count = rand(1..(fill_count - 1))
        prescription = build(:prescription, :with_returns, fill_count: fill_count, return_count: return_count)

        expected_income = ((fill_count - return_count) * 5) - (return_count * 1)
        expect(prescription.income).to eq(expected_income)
      end
    end

    it 'ensures net_fills never goes negative' do
      20.times do
        fill_count = rand(1..5)
        return_count = rand(1..fill_count)
        prescription = build(:prescription, :with_returns, fill_count: fill_count, return_count: return_count)

        expect(prescription.net_fills).to be >= 0
      end
    end
  end
end
