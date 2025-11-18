# frozen_string_literal: true

require "set"

FactoryBot.define do
  factory :patient, class: Patient do
    name { Faker::Name.first_name }

    initialize_with { new(name) }

    trait :with_prescriptions do
      transient do
        prescription_count { 1 }
        prescription_traits { [:created] }
      end

      after(:build) do |patient, evaluator|
        used_drug_names = Set.new
        evaluator.prescription_count.times do
          # Ensure unique drug names
          drug_name = loop do
            name = Faker::Alphanumeric.alphanumeric(number: 1, min_alpha: 1).upcase
            break name unless used_drug_names.include?(name)
          end
          used_drug_names.add(drug_name)
          prescription = build(:prescription, *evaluator.prescription_traits, patient_name: patient.name, drug_name: drug_name)
          patient.instance_variable_get(:@prescriptions)[drug_name] = prescription
        end
      end
    end

    trait :with_filled_prescriptions do
      transient do
        prescription_count { 1 }
        fill_count { 1 }
      end

      after(:build) do |patient, evaluator|
        used_drug_names = Set.new
        evaluator.prescription_count.times do
          # Ensure unique drug names
          drug_name = loop do
            name = Faker::Alphanumeric.alphanumeric(number: 1, min_alpha: 1).upcase
            break name unless used_drug_names.include?(name)
          end
          used_drug_names.add(drug_name)
          prescription = build(:prescription, :with_fills, patient_name: patient.name, drug_name: drug_name, fill_count: evaluator.fill_count)
          patient.instance_variable_get(:@prescriptions)[drug_name] = prescription
        end
      end
    end
  end
end

