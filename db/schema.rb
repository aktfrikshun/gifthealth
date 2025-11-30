# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_30_000002) do
  create_table "patients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_patients_on_name", unique: true
  end

  create_table "prescriptions", force: :cascade do |t|
    t.boolean "created", default: false, null: false
    t.datetime "created_at", null: false
    t.string "drug_name", null: false
    t.integer "fill_count", default: 0, null: false
    t.integer "patient_id", null: false
    t.integer "return_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id", "drug_name"], name: "index_prescriptions_on_patient_id_and_drug_name", unique: true
    t.index ["patient_id"], name: "index_prescriptions_on_patient_id"
  end

  add_foreign_key "prescriptions", "patients"
end
