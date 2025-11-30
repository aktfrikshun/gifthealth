# frozen_string_literal: true

class PrescriptionsController < ApplicationController
  before_action :set_prescription, only: [:show, :edit, :update, :destroy, :increment_fill, :decrement_fill]
  
  def index
    @patients = Patient.includes(:prescriptions)
                      .select { |p| p.has_created_prescriptions? }
                      .sort_by { |p| [-p.total_fills, p.total_income] }
    @report_generated = @patients.any?
  end
  
  def show
    @patient = @prescription.patient
  end
  
  def new
    @prescription = Prescription.new
    @patients = Patient.all.order(:name)
  end
  
  def create
    patient = Patient.find_or_create_by!(name: prescription_params[:patient_name])
    @prescription = patient.prescriptions.build(
      drug_name: prescription_params[:drug_name],
      created: prescription_params[:created] == '1',
      fill_count: prescription_params[:fill_count].to_i,
      return_count: prescription_params[:return_count].to_i
    )
    
    if @prescription.save
      redirect_to prescriptions_path, notice: 'Prescription was successfully created.'
    else
      @patients = Patient.all.order(:name)
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @patients = Patient.all.order(:name)
  end
  
  def update
    if prescription_params[:patient_name].present?
      patient = Patient.find_or_create_by!(name: prescription_params[:patient_name])
      @prescription.patient = patient
    end
    
    if @prescription.update(prescription_params.except(:patient_name))
      redirect_to prescriptions_path, notice: 'Prescription was successfully updated.'
    else
      @patients = Patient.all.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    patient = @prescription.patient
    @prescription.destroy
    
    # Clean up patient if they have no more prescriptions
    if patient.prescriptions.empty?
      patient.destroy
    end
    
    redirect_to prescriptions_path, notice: 'Prescription was successfully deleted.'
  end
  
  def increment_fill
    @prescription.fill
    redirect_to prescriptions_path, notice: 'Fill count incremented.'
  end
  
  def decrement_fill
    if @prescription.fill_count > 0
      @prescription.return_fill
      redirect_to prescriptions_path, notice: 'Fill count decremented (return processed).'
    else
      redirect_to prescriptions_path, alert: 'Cannot decrement: fill count is already 0.'
    end
  end

  def upload
    unless params[:file].present?
      redirect_to root_path, alert: 'Please select a file to upload'
      return
    end

    file = params[:file]
    unless ['text/csv', 'text/plain', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'].include?(file.content_type)
      redirect_to root_path, alert: 'Please upload a CSV, TXT, or Excel file'
      return
    end

    begin
      processor = PrescriptionEventProcessor.new
      parser = FileParserService.new(file.tempfile.path, file.content_type)
      
      event_count = 0
      parser.each_row do |row|
        next if row.compact.empty? # Skip empty rows
        
        patient_name, drug_name, event_name = row[0..2]
        next unless patient_name && drug_name && event_name
        
        processor.process_event(
          patient_name: patient_name.to_s.strip,
          drug_name: drug_name.to_s.strip,
          event_name: event_name.to_s.strip.downcase
        )
        event_count += 1
      end

      redirect_to root_path, notice: "Successfully processed #{event_count} prescription events"
    rescue StandardError => e
      redirect_to root_path, alert: "Error processing file: #{e.message}"
    end
  end

  def process_events
    unless params[:events].present?
      render json: { error: 'No events provided' }, status: :bad_request
      return
    end

    begin
      processor = PrescriptionEventProcessor.new
      events = params[:events].split("\n").reject(&:blank?)
      
      events.each do |line|
        processor.process_line(line)
      end

      redirect_to root_path, notice: "Successfully processed #{events.count} events"
    rescue StandardError => e
      redirect_to root_path, alert: "Error processing events: #{e.message}"
    end
  end
  
  private
  
  def set_prescription
    @prescription = Prescription.find(params[:id])
  end
  
  def prescription_params
    params.require(:prescription).permit(:patient_name, :drug_name, :created, :fill_count, :return_count)
  end
end
