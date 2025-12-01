# frozen_string_literal: true

require 'redcarpet'
require 'cgi'

# Custom renderer to ensure proper code block formatting with preserved whitespace
class CustomHTMLRenderer < Redcarpet::Render::HTML
  def block_code(code, language)
    lang_class = language ? " class=\"language-#{language}\"" : ''
    # Preserve whitespace by escaping HTML but keeping all whitespace intact
    escaped_code = code.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
    "<pre><code#{lang_class}>#{escaped_code}</code></pre>"
  end
end

# Serves documentation markdown files and ERD SVG diagrams
class DocumentsController < ApplicationController
  def show
    doc_name = params[:name]
    format = params[:format]

    # Handle ERD viewer
    if doc_name == 'erd'
      render :erd
      return
    end

    # Validate filename to prevent path traversal
    # Only allow alphanumeric characters, hyphens, and underscores
    unless doc_name.match?(/\A[a-zA-Z0-9_-]+\z/)
      render plain: 'Invalid document name', status: :bad_request
      return
    end

    # Handle SVG files
    if format == 'svg'
      # Whitelist allowed SVG files
      allowed_svgs = %w[erd-diagram]

      unless allowed_svgs.include?(doc_name)
        render plain: 'SVG file not found', status: :not_found
        return
      end

      file_path = Rails.root.join('documents', "#{doc_name}.svg")
      if File.exist?(file_path)
        send_file file_path, type: 'image/svg+xml', disposition: 'inline'
      else
        render plain: 'File not found', status: :not_found
      end
      return
    end

    # Whitelist allowed documents
    allowed_docs = %w[API_DOCUMENTATION RAILS_BRANCH_CHANGES REQUIREMENTS SOLID_PRINCIPLES TECHNOLOGY_CHOICES]

    unless allowed_docs.include?(doc_name)
      render plain: 'Document not found', status: :not_found
      return
    end

    file_path = Rails.root.join('documents', "#{doc_name}.md")

    unless File.exist?(file_path)
      render plain: 'Document not found', status: :not_found
      return
    end

    markdown_content = File.read(file_path)
    @title = doc_name.split('_').map(&:capitalize).join(' ')

    # Render markdown to HTML with header IDs for anchor links
    renderer = CustomHTMLRenderer.new(
      with_toc_data: true
    )
    markdown = Redcarpet::Markdown.new(renderer,
                                       autolink: true,
                                       tables: true,
                                       fenced_code_blocks: true,
                                       no_intra_emphasis: true,
                                       strikethrough: true,
                                       superscript: true,
                                       space_after_headers: true)

    @content = markdown.render(markdown_content).html_safe

    render :show
  end
end
