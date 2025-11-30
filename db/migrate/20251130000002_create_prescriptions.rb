# frozen_string_literal: true

class CreatePrescriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :prescriptions do |t|
      t.references :patient, null: false, foreign_key: true
      t.string :drug_name, null: false
      t.boolean :created, default: false, null: false
      t.integer :fill_count, default: 0, null: false
      t.integer :return_count, default: 0, null: false
      
      t.timestamps
      
      t.index [:patient_id, :drug_name], unique: true
    end
  end
end
