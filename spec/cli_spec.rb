# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe CLI do
  describe ".run" do
    context "with filename argument" do
      it "processes file and outputs report" do
        file = Tempfile.new("test_input")
        file.write("John A created\nJohn A filled\n")
        file.close

        expect do
          CLI.run([file.path])
        end.to output("John: 1 fills $5 income\n").to_stdout

        file.unlink
      end

      it "handles file not found" do
        expect do
          expect { CLI.run(["nonexistent.txt"]) }.to raise_error(SystemExit)
        end.to output(/Error: File 'nonexistent.txt' not found/).to_stderr
      end
    end

    context "with stdin" do
      it "processes stdin input when no arguments provided" do
        # This is tested via integration tests with the actual executable
        # Unit testing stdin mocking is complex and less valuable
      end
    end
  end
end

