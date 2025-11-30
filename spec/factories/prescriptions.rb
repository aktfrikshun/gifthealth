# frozen_string_literal: true

FactoryBot.define do
  factory :prescription, class: Prescription do
    association :patient, factory: :patient
    drug_name { Faker::Alphanumeric.alphanumeric(number: 1, min_alpha: 1).upcase }

    trait :created do
      created { true }
    end

    trait :filled do
      created { true }
      fill_count { 1 }
    end

    trait :with_fills do
      created { true }
      transient do
        fill_count { 1 }
      end

      after(:build) do |prescription, evaluator|
        prescription.fill_count = evaluator.fill_count
      end
    end

    trait :with_returns do
      with_fills
      transient do
        return_count { 1 }
      end

      after(:build) do |prescription, evaluator|
        prescription.return_count = evaluator.return_count
      end
    end
  end
end

