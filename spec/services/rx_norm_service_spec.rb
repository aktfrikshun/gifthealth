# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RxNormService do
  describe '.autocomplete' do
    it 'returns empty array for blank query' do
      expect(described_class.autocomplete('')).to eq([])
    end

    it 'returns empty array for short query' do
      expect(described_class.autocomplete('a')).to eq([])
    end

    it 'returns drug suggestions for valid query' do
      stub_request(:get, %r{https://rxnav.nlm.nih.gov/REST/approximateTerm.json})
        .to_return(
          status: 200,
          body: {
            approximateGroup: {
              candidate: [
                { rxcui: '1191', name: 'Aspirin', score: '10' },
                { rxcui: '1192', name: 'Aspirin Low', score: '9' },
                { rxcui: '1193', score: '8' } # No name - should be filtered out
              ]
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      results = described_class.autocomplete('aspirin', limit: 5)

      expect(results).to be_an(Array)
      expect(results.size).to eq(2) # Only 2 with names
      expect(results.first).to have_key(:name)
      expect(results.first).to have_key(:display)
      expect(results.first).to have_key(:rxcui)
    end

    it 'handles API errors gracefully' do
      allow(Net::HTTP).to receive(:new).and_raise(StandardError.new('Connection failed'))

      results = described_class.autocomplete('aspirin')
      expect(results).to eq([])
    end
  end

  describe '.validate_drug' do
    it 'returns false for blank drug name' do
      expect(described_class.validate_drug('')).to be false
      expect(described_class.validate_drug(nil)).to be false
    end

    it 'returns true for valid drug name' do
      stub_request(:get, %r{https://rxnav.nlm.nih.gov/REST/drugs.json})
        .to_return(
          status: 200,
          body: { drugGroup: { conceptGroup: [{ conceptProperties: [{ rxcui: '1191', name: 'Aspirin' }] }] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(described_class.validate_drug('Aspirin')).to be true
    end

    it 'returns false for invalid drug name' do
      stub_request(:get, %r{https://rxnav.nlm.nih.gov/REST/drugs.json})
        .to_return(
          status: 200,
          body: { drugGroup: { conceptGroup: [] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(described_class.validate_drug('NotARealDrugName12345')).to be false
    end

    it 'handles API errors gracefully' do
      allow(Net::HTTP).to receive(:new).and_raise(StandardError.new('Connection failed'))

      result = described_class.validate_drug('Aspirin')
      expect(result).to be false
    end
  end

  describe '.get_rxcui' do
    it 'returns nil for blank drug name' do
      expect(described_class.get_rxcui('')).to be_nil
      expect(described_class.get_rxcui(nil)).to be_nil
    end

    it 'returns RxCUI for valid drug' do
      stub_request(:get, %r{https://rxnav.nlm.nih.gov/REST/rxcui.json})
        .to_return(
          status: 200,
          body: { idGroup: { rxnormId: ['1191'] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      rxcui = described_class.get_rxcui('Aspirin')

      expect(rxcui).to be_a(String)
      expect(rxcui).not_to be_empty
    end

    it 'handles API errors gracefully' do
      allow(Net::HTTP).to receive(:new).and_raise(StandardError.new('Connection failed'))

      result = described_class.get_rxcui('Aspirin')
      expect(result).to be_nil
    end
  end
end
