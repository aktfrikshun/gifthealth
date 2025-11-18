# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prescription do
  # Using factory for consistency, but keeping explicit values for clarity in these tests
  let(:prescription) { Prescription.new(patient_name: "John", drug_name: "A") }
  
  # Example of using factory with random data for property-based testing
  let(:random_prescription) { build(:prescription) }

  describe "#created?" do
    it "returns false initially" do
      expect(prescription.created?).to be false
    end

    it "returns true after marking as created" do
      prescription.mark_created
      expect(prescription.created?).to be true
    end
  end

  describe "#fill" do
    it "returns false if prescription is not created" do
      expect(prescription.fill).to be false
      expect(prescription.net_fills).to eq(0)
    end

    it "increments fill count after creation" do
      prescription.mark_created
      expect(prescription.fill).to be true
      expect(prescription.net_fills).to eq(1)
    end

    it "allows multiple fills" do
      prescription.mark_created
      prescription.fill
      prescription.fill
      expect(prescription.net_fills).to eq(2)
    end
  end

  describe "#return_fill" do
    it "returns false if prescription is not created" do
      expect(prescription.return_fill).to be false
    end

    it "returns false if there are no fills to return" do
      prescription.mark_created
      expect(prescription.return_fill).to be false
    end

    it "decrements net fills when returning" do
      prescription.mark_created
      prescription.fill
      prescription.fill
      expect(prescription.return_fill).to be true
      expect(prescription.net_fills).to eq(1)
    end

    it "cannot return more than filled" do
      prescription.mark_created
      prescription.fill
      prescription.return_fill
      expect(prescription.return_fill).to be false
      expect(prescription.net_fills).to eq(0)
    end
  end

  describe "#income" do
    it "returns 0 for uncreated prescription" do
      expect(prescription.income).to eq(0)
    end

    it "returns $5 per net fill" do
      prescription.mark_created
      prescription.fill
      expect(prescription.income).to eq(5) # 1 net fill * 5 - 0 returns * 1
      prescription.fill
      expect(prescription.income).to eq(10) # 2 net fills * 5 - 0 returns * 1
    end

    it "calculates income correctly with returns (return cancels fill income + $1 penalty)" do
      prescription.mark_created
      prescription.fill
      prescription.fill
      prescription.return_fill
      # 2 fills, 1 return: net_fills = 1, return_count = 1
      # income = net_fills * 5 - return_count * 1 = 1 * 5 - 1 * 1 = 4
      expect(prescription.income).to eq(4)
    end

    it "calculates negative income correctly with multiple returns" do
      prescription.mark_created
      prescription.fill
      prescription.return_fill
      prescription.fill
      prescription.return_fill
      # 2 fills, 2 returns: net_fills = 0, return_count = 2
      # income = net_fills * 5 - return_count * 1 = 0 * 5 - 2 * 1 = -2
      expect(prescription.income).to eq(-2)
    end
  end
end

