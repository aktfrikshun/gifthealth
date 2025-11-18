# frozen_string_literal: true

FactoryBot.define do
  factory :prescription, class: Prescription do
    association :patient, factory: :patient
    drug_name { Faker::Alphanumeric.alphanumeric(number: 1, min_alpha: 1).upcase }

    initialize_with { new(patient: patient, drug_name: drug_name) }

    trait :created do
      after(:build) do |prescription|
        prescription.mark_created
      end
    end

    trait :filled do
      created
      after(:build) do |prescription|
        prescription.fill
      end
    end

    trait :with_fills do
      created
      transient do
        fill_count { 1 }
      end

      after(:build) do |prescription, evaluator|
        evaluator.fill_count.times { prescription.fill }
      end
    end

    trait :with_returns do
      with_fills
      transient do
        return_count { 1 }
      end

      after(:build) do |prescription, evaluator|
        evaluator.return_count.times { prescription.return_fill }
      end
    end
  end
end

