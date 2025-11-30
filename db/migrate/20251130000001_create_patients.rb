# frozen_string_literal: true

class CreatePatients < ActiveRecord::Migration[8.0]
  def change
    create_table :patients do |t|
      t.string :name, null: false, index: { unique: true }
      
      t.timestamps
    end
  end
end
