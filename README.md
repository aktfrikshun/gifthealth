# Prescription Event Processor

A Ruby command-line application that processes prescription events and generates income reports for a pharmacy system.

## Requirements

- Ruby >= 3.4.0 (tested with Ruby 3.4.1 via rbenv)
- Bundler (for dependency management)
- rbenv (recommended for Ruby version management)

## Installation

```bash
bundle install
```

## Usage

The application accepts input either via a filename argument or via stdin:

```bash
# Using a filename
./bin/prescription_processor spec/fixtures/sample_input.txt

# Using stdin
cat spec/fixtures/sample_input.txt | ./bin/prescription_processor
```

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/prescription_spec.rb
bundle exec rspec spec/performance_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

## Architecture and Design Decisions

### Overview

The solution is organized into a clean, object-oriented architecture with clear separation of concerns. The design follows SOLID principles and emphasizes testability and maintainability.

### Core Components

#### 1. `Prescription` Class (`lib/prescription.rb`)

Represents a single prescription and tracks its state. This is the core domain object that encapsulates the business rules for prescription lifecycle.

**Key Design Decisions:**
- **State Management**: Uses simple instance variables (`@created`, `@fill_count`, `@return_count`) rather than a state machine. This keeps the implementation simple while still being clear and maintainable.
- **Validation**: Methods return `true`/`false` to indicate success, allowing callers to handle invalid operations gracefully.
- **Income Calculation**: The income formula is `(net_fills * 5) - (return_count * 1)`. This reflects that returns cancel out the income from a fill (hence using `net_fills` which is `fill_count - return_count`) and also incur a $1 penalty per return.

**Data Structures:**
- Simple integer counters for fills and returns
- Boolean flag for creation state

#### 2. `Patient` Class (`lib/patient.rb`)

Aggregates multiple prescriptions for a single patient and provides aggregate statistics.

**Key Design Decisions:**
- **Prescription Storage**: Uses a hash keyed by drug name (`@prescriptions[drug_name]`) for O(1) lookup when processing events. This is efficient since we need to look up prescriptions frequently during event processing.
- **Lazy Creation**: Prescriptions are created on-demand via `get_or_create_prescription`, which simplifies the event processing logic.
- **Aggregation**: Provides `total_fills` and `total_income` methods that sum across all prescriptions, keeping the aggregation logic encapsulated.

**Data Structures:**
- Hash of prescriptions keyed by drug name

#### 3. `PrescriptionEventProcessor` Class (`lib/prescription_event_processor.rb`)

Orchestrates the event processing and report generation.

**Key Design Decisions:**
- **Event Processing**: Separates line parsing (`process_line`) from event handling (`process_event`), making the code more testable and allowing for easy extension to other input formats.
- **Patient Storage**: Uses a hash keyed by patient name for O(1) patient lookup.
- **Report Generation**: Filters out patients with no created prescriptions before generating the report, ensuring only relevant patients appear in the output.
- **Sorting**: Sorts patients alphabetically by name for consistent, predictable output.

**Data Structures:**
- Hash of patients keyed by patient name

#### 4. `CLI` Class (`lib/cli.rb`)

Handles command-line interface concerns.

**Key Design Decisions:**
- **Input Source Abstraction**: Determines input source (file vs stdin) and passes an IO-like object to the processor. This keeps the processor agnostic of input source.
- **Error Handling**: Provides user-friendly error messages for file not found scenarios.
- **Separation of Concerns**: CLI only handles I/O concerns, delegating all business logic to the processor.

### Design Tradeoffs

#### 1. **Simplicity vs. Extensibility**

I chose a simple, straightforward design over a more complex, extensible one. For example:
- **Chose**: Simple case statement for event types
- **Alternative**: Strategy pattern or command pattern
- **Rationale**: With only 3 event types that are unlikely to change, the added complexity of a pattern isn't justified. The case statement is clear and easy to understand.

#### 2. **In-Memory Processing vs. Streaming**

I chose to process all events in memory before generating the report.
- **Chose**: Load all events, process, then generate report
- **Alternative**: Stream processing with incremental report generation
- **Rationale**: For the expected scale (pharmacy events), memory usage is not a concern. The in-memory approach is simpler, easier to test, and allows for easier sorting and filtering of results.

#### 3. **Explicit State Tracking vs. Event Sourcing**

I chose explicit state tracking (counters) over event sourcing.
- **Chose**: Maintain fill_count and return_count
- **Alternative**: Store all events and replay to calculate state
- **Rationale**: The requirements don't need event history, only current state. Explicit counters are simpler, more efficient, and easier to reason about.

#### 4. **Income Calculation Formula**

The income calculation uses `(net_fills * 5) - (return_count * 1)`.
- This reflects that returns cancel out fills (hence `net_fills = fill_count - return_count`)
- Each return also incurs a $1 penalty
- This matches the expected output from the requirements

### Testing Strategy

The test suite is organized to mirror the code structure and includes comprehensive testing tools:

1. **Unit Tests**: Each class has comprehensive unit tests covering:
   - Happy paths
   - Edge cases (e.g., returns without fills, fills before creation)
   - Boundary conditions
   - Business rule validation

2. **Integration Tests**: End-to-end tests that verify:
   - The complete workflow from input to output
   - The exact expected output format from requirements
   - Both file and stdin input methods

3. **FactoryBot & Faker**: Test data generation using factories:
   - **Prescription Factory**: Creates prescriptions with traits like `:created`, `:filled`, `:with_fills`, `:with_returns`
   - **Patient Factory**: Creates patients with traits like `:with_prescriptions`, `:with_filled_prescriptions`
   - Uses Faker for realistic random data generation
   - Enables property-based testing with varied data

4. **Performance/Load Tests**: Validates system performance:
   - Processes 1000+ events and measures throughput
   - Tests realistic prescription lifecycle patterns
   - Benchmarks event processing and report generation
   - Currently achieving ~200,000+ events per second

5. **Test Coverage**: The tests cover:
   - All event types and their interactions
   - Income calculation correctness
   - Edge cases (invalid events, missing prescriptions, etc.)
   - Output formatting
   - Performance characteristics

### Code Organization

```
lib/
  ├── prescription.rb              # Core domain object
  ├── patient.rb                   # Patient aggregation
  ├── prescription_event_processor.rb  # Event processing orchestration
  └── cli.rb                       # Command-line interface

spec/
  ├── spec_helper.rb
  ├── factories/
  │   ├── prescriptions.rb      # FactoryBot factories for prescriptions
  │   └── patients.rb           # FactoryBot factories for patients
  ├── fixtures/
  │   └── sample_input.txt      # Sample input file for testing
  ├── prescription_spec.rb
  ├── patient_spec.rb
  ├── prescription_event_processor_spec.rb
  ├── prescription_factory_spec.rb    # Factory tests with property-based testing
  ├── patient_factory_spec.rb         # Factory tests
  ├── performance_spec.rb             # Load and performance tests
  ├── cli_spec.rb
  └── integration_spec.rb

bin/
  └── prescription_processor       # Executable entry point
```

### Assumptions Made

1. **Input Format**: Assumed that input lines are space-delimited with exactly 3 parts (patient name, drug name, event name). Invalid lines are silently ignored.

2. **Event Ordering**: Assumed events are processed in the order they appear in the input file.

3. **Patient/Drug Uniqueness**: Assumed that patient names and drug names don't contain spaces (as stated in requirements).

4. **Output Format**: Assumed the output format should match the example exactly, including the colon after patient name and the specific wording ("fills", "income").

5. **Income Calculation**: Interpreted "returns cancel out a prior filled event" to mean returns cancel both the fill count and the income from that fill, plus incur a $1 penalty.

6. **Patients Without Created Prescriptions**: Assumed that patients who only have events for prescriptions that were never created should not appear in the output.

### Notable Implementation Details

1. **Return Logic**: Returns can only occur if there are more fills than returns. This prevents invalid states.

2. **Fill Logic**: Fills can only occur after a prescription is created. Fills before creation are silently ignored.

3. **Report Filtering**: Only patients with at least one created prescription appear in the report, even if they have other events for non-created prescriptions.

4. **Sorting**: Patients are sorted alphabetically by name for consistent output ordering.

## Example

Given the sample input:

```
Nick A created
Mark B created
Mark B filled
Mark C filled
Mark B returned
John E created
Mark B filled
Mark B filled
Paul D filled
John E filled
John E returned
```

The output is:

```
John: 0 fills -$1 income
Mark: 2 fills $9 income
Nick: 0 fills $0 income
```

## Future Enhancements (If Needed)

If this were to be extended, potential improvements could include:

1. **Error Reporting**: More detailed error messages for invalid events
2. **Logging**: Add logging for debugging and audit trails
3. **Configuration**: Make income amounts ($5 per fill, $1 per return) configurable
4. **Performance**: Performance tests show the system can handle 200,000+ events per second. For very large files (millions of events), consider streaming processing
5. **Validation**: More robust input validation and error handling
6. **Output Formats**: Support for JSON, CSV, or other output formats

