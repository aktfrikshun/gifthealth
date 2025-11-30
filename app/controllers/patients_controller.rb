# frozen_string_literal: true

class PatientsController < ApplicationController
  before_action :set_patient, only: [:destroy, :clear_prescriptions]
  
  def index
    @patients = Patient.includes(:prescriptions).order(:name)
  end
  
  def destroy
    @patient.destroy
    redirect_to patients_path, notice: 'Patient and all prescriptions were successfully deleted.'
  end
  
  def clear_prescriptions
    @patient.prescriptions.destroy_all
    redirect_to patients_path, notice: 'All prescriptions for this patient were cleared.'
  end
  
  def reset_all
    Patient.destroy_all
    redirect_to prescriptions_path, notice: 'All patients and prescriptions have been cleared from the database.'
  end
  
  private
  
  def set_patient
    @patient = Patient.find(params[:id])
  end
end
