# frozen_string_literal: true

FactoryBot.define do
  factory :patient, class: Patient do
    name { Faker::Name.first_name }

    trait :with_prescriptions do
      transient do
        prescription_count { 1 }
        prescription_traits { [:created] }
      end

      after(:create) do |patient, evaluator|
        used_drug_names = Set.new
        evaluator.prescription_count.times do
          # Ensure unique drug names
          drug_name = loop do
            name = Faker::Alphanumeric.alphanumeric(number: 1, min_alpha: 1).upcase
            break name unless used_drug_names.include?(name)
          end
          used_drug_names.add(drug_name)
          create(:prescription, *evaluator.prescription_traits, patient: patient, drug_name: drug_name)
        end
      end
    end

    trait :with_filled_prescriptions do
      transient do
        prescription_count { 1 }
        fill_count { 1 }
      end

      after(:create) do |patient, evaluator|
        used_drug_names = Set.new
        evaluator.prescription_count.times do
          # Ensure unique drug names
          drug_name = loop do
            name = Faker::Alphanumeric.alphanumeric(number: 1, min_alpha: 1).upcase
            break name unless used_drug_names.include?(name)
          end
          used_drug_names.add(drug_name)
          create(:prescription, :with_fills, patient: patient, drug_name: drug_name,
                                             fill_count: evaluator.fill_count)
        end
      end
    end
  end
end
