# frozen_string_literal: true

# Creates patients table with unique name constraint
class CreatePatients < ActiveRecord::Migration[8.0]
  def change
    create_table :patients do |t|
      t.string :name, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
