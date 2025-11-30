# frozen_string_literal: true

require 'csv'
require 'roo'

class FileParserService
  def initialize(file_path, content_type)
    @file_path = file_path
    @content_type = content_type
  end

  def each_row(&block)
    case @content_type
    when 'text/csv'
      parse_csv(&block)
    when 'text/plain'
      parse_txt(&block)
    when 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      parse_excel(&block)
    else
      raise "Unsupported file type: #{@content_type}"
    end
  end

  private

  def parse_csv(&block)
    CSV.foreach(@file_path, headers: false) do |row|
      yield row.to_a
    end
  end

  def parse_txt(&block)
    File.foreach(@file_path) do |line|
      next if line.strip.empty?
      yield line.strip.split(/\s+/)
    end
  end

  def parse_excel(&block)
    spreadsheet = Roo::Spreadsheet.open(@file_path)
    spreadsheet.each_row_streaming do |row|
      yield row.map(&:value)
    end
  end
end
