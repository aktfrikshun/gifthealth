# Prescription Event Processor

A Ruby command-line application that processes prescription events and generates income reports for a pharmacy system.

## Requirements

- Ruby >= 3.4.0
- Bundler (for dependency management)

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
bundle exec rspec spec/models/prescription_spec.rb
bundle exec rspec spec/performance_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

## Architecture and Design Decisions

### Overview

The solution is organized into a clean, object-oriented architecture with clear separation of concerns. The design follows SOLID principles and emphasizes testability and maintainability. See `documents/SOLID_PRINCIPLES.md` for detailed documentation on how SOLID principles are applied in this codebase.

For information on technology choices and why Ruby with Bundler was selected (without Rails), see `documents/TECHNOLOGY_CHOICES.md`.

### Core Components

#### 1. `Prescription` Model (`app/models/prescription.rb`)

Represents a single prescription and tracks its state. This is the core domain object that encapsulates the business rules for prescription lifecycle.

**Key Design Decisions:**
- **Relationships**: Belongs to a Patient (has_one patient). Maintains a reference to the patient object rather than just storing the patient name.
- **State Management**: Uses simple instance variables (`@created`, `@fill_count`, `@return_count`) rather than a state machine. This keeps the implementation simple while still being clear and maintainable.
- **Validations**: 
  - Patient must be present and an instance of Patient
  - Drug name must be present and not empty
  - Raises `ArgumentError` with descriptive messages for invalid input
- **Income Calculation**: The income formula is `(net_fills * 5) - (return_count * 1)`. This reflects that returns cancel out the income from a fill (hence using `net_fills` which is `fill_count - return_count`) and also incur a $1 penalty per return.

**Data Structures:**
- Reference to Patient object
- Simple integer counters for fills and returns
- Boolean flag for creation state

#### 2. `Patient` Model (`app/models/patient.rb`)

Aggregates multiple prescriptions for a single patient and provides aggregate statistics.

**Key Design Decisions:**
- **Relationships**: Has many Prescriptions (has_many :prescriptions). Manages prescriptions through a hash keyed by drug name.
- **Prescription Storage**: Uses a hash keyed by drug name (`@prescriptions[drug_name]`) for O(1) lookup when processing events. This is efficient since we need to look up prescriptions frequently during event processing.
- **Lazy Creation**: Prescriptions are created on-demand via `get_or_create_prescription`, which simplifies the event processing logic.
- **Validations**:
  - Name must be present and not empty
  - When adding prescriptions via `add_prescription`, validates that the prescription belongs to this patient
- **Aggregation**: Provides `total_fills` and `total_income` methods that sum across all prescriptions, keeping the aggregation logic encapsulated.

**Data Structures:**
- Hash of prescriptions keyed by drug name

#### 3. `PrescriptionEventProcessor` Service (`app/services/prescription_event_processor.rb`)

Orchestrates the event processing and report generation. Contains the core business logic.

**Key Design Decisions:**
- **Event Processing**: Separates line parsing (`process_line`) from event handling (`process_event`), making the code more testable and allowing for easy extension to other input formats.
- **Patient Storage**: Uses a hash keyed by patient name for O(1) patient lookup.
- **Report Generation**: Filters out patients with no created prescriptions before generating the report, ensuring only relevant patients appear in the output.
- **Sorting**: Sorts patients alphabetically by name for consistent, predictable output.

**Data Structures:**
- Hash of patients keyed by patient name

#### 4. `CLI` Handler (`app/handlers/cli.rb`)

Handles command-line interface concerns. This is an interface adapter that translates CLI input into service calls.

**Key Design Decisions:**
- **Input Source Abstraction**: Determines input source (file vs stdin) and passes an IO-like object to the processor. This keeps the processor agnostic of input source.
- **Error Handling**: Provides user-friendly error messages for file not found scenarios using `warn` for better Ruby conventions.
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

5. **Model Validations**: Comprehensive validation tests ensure:
   - Patient and Prescription models enforce data integrity
   - Relationships are properly maintained
   - Invalid data is rejected with clear error messages

6. **Test Coverage**: The tests cover:
   - All event types and their interactions
   - Income calculation correctness
   - Edge cases (invalid events, missing prescriptions, etc.)
   - Output formatting
   - Performance characteristics
   - Model relationships and validations

### Code Organization

The codebase follows an MVC-like architecture, organized into clear layers:

```
app/
  ├── models/
  │   ├── prescription.rb              # Core domain object - prescription state
  │   └── patient.rb                   # Patient aggregation model
  ├── services/
  │   └── prescription_event_processor.rb  # Business logic - event processing
  └── handlers/
      └── cli.rb                       # Interface layer - command-line handler

spec/
  ├── spec_helper.rb
  ├── factories/
  │   ├── prescriptions.rb      # FactoryBot factories for prescriptions
  │   └── patients.rb           # FactoryBot factories for patients
  ├── fixtures/
  │   └── sample_input.txt      # Sample input file for testing
  ├── models/
  │   ├── prescription_spec.rb
  │   └── patient_spec.rb
  ├── services/
  │   └── prescription_event_processor_spec.rb
  ├── handlers/
  │   └── cli_spec.rb
  ├── performance_spec.rb             # Load and performance tests
  └── integration_spec.rb

bin/
  └── prescription_processor       # Executable entry point
```

**Architecture Layers:**
- **Models** (`app/models/`): Domain objects representing business entities (Prescription, Patient)
- **Services** (`app/services/`): Business logic and orchestration (PrescriptionEventProcessor)
- **Handlers** (`app/handlers/`): Interface adapters for different input/output mechanisms (CLI, future API handlers, etc.)

This structure makes it easy to add new interfaces (web API, message queue consumers, etc.) without modifying core business logic.

### Assumptions Made

1. **Input Format**: Assumed that input lines are space-delimited with exactly 3 parts (patient name, drug name, event name). Invalid lines are silently ignored.

2. **Event Ordering**: Assumed events are processed in the order they appear in the input file.

3. **Patient/Drug Uniqueness**: Assumed that patient names and drug names don't contain spaces (as stated in requirements).

4. **Output Format**: Assumed the output format should match the example exactly, including the colon after patient name and the specific wording ("fills", "income").

5. **Income Calculation**: Interpreted "returns cancel out a prior filled event" to mean returns cancel both the fill count and the income from that fill, plus incur a $1 penalty.

6. **Patients Without Created Prescriptions**: Assumed that patients who only have events for prescriptions that were never created should not appear in the output.

### Model Relationships and Validations

**Relationships:**
- **Patient has_many Prescriptions**: A patient can have zero or many prescriptions. Prescriptions are managed through the `prescriptions` collection.
- **Prescription belongs_to Patient**: Each prescription must belong to exactly one patient. The prescription maintains a reference to its patient object.

**Validations:**
- **Patient**: Name must be present and not empty. Raises `ArgumentError` if validation fails.
- **Prescription**: 
  - Patient must be present and an instance of Patient
  - Drug name must be present and not empty
  - When adding a prescription to a patient, validates that the prescription's patient matches

These validations ensure data integrity and prevent invalid states from being created.

### Notable Implementation Details

1. **Return Logic**: Returns can only occur if there are more fills than returns. This prevents invalid states.

2. **Fill Logic**: Fills can only occur after a prescription is created. Fills before creation are silently ignored. **Question for product owner: Should these be silently ignored, or should we abort or log warning?

3. **Report Filtering**: Only patients with at least one created prescription appear in the report, even if they have other events for non-created prescriptions. **Question for product owner: Should we report on patients with events that for missing prescriptions?

4. **Sorting**: Patients are sorted alphabetically by name for consistent output ordering.

5. **Relationship Integrity**: Prescriptions maintain a bidirectional relationship with patients, ensuring data consistency throughout the system.

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
4. **Drug-Based Pricing**: Allow for the creation of Drug entities with associated name and pricing:
   - **Drug Model**: Create a Drug entity with:
     - Drug name/identifier
     - Fill price (revenue per fill)
     - Return cost (cost per return)
   - **Prescription Updates**: A prescription would reference both a Patient and a Drug
   - **Dynamic Income Calculation**: Prescription income would be derived from the Drug-specific `fill_price` and `return_cost` rather than hardcoded values
   - **Benefits**:
     - Support for different pricing tiers (generic vs. brand name drugs)
     - Flexible pricing model that can change over time
     - More accurate financial reporting per drug type
     - Ability to model complex pricing scenarios (insurance tiers, discounts, etc.)
5. **Performance**: Performance tests show the system can handle 200,000+ events per second. For very large files (millions of events), consider streaming processing
6. **Enhanced Validation**: Additional validation rules and custom validators for complex business rules
7. **Output Formats**: Support for JSON, CSV, or other output formats
8. **Event Persistence & Change Tracking**: Add event history and audit capabilities:
   - **Event Storage**: Persist all prescription events to a database (e.g., PostgreSQL, DynamoDB) for historical tracking
   - **Change Tracking**: Implement event sourcing or audit logging to track:
     - When events were processed
     - Who/what system created each event
     - Full event history for each prescription
     - Ability to replay events for debugging or reprocessing
   - **Event History Viewing**: Provide APIs and UI to:
     - View complete event timeline for a prescription
     - Query events by patient, drug, date range, or event type
     - Track state changes over time
     - Generate audit reports
   - **Benefits**:
     - Complete audit trail for compliance
     - Ability to debug issues by reviewing event history
     - Support for event replay and reprocessing
     - Historical analysis and reporting capabilities
9. **Web Interface & Serverless Deployment**: Transform into a stateless, serverless utility with:
   - **Web Interface**: RESTful API and web UI for receiving input via file uploads or direct API calls
   - **Event Ingestion**: Use asynchronous event ingestion such as AWS SQS (Simple Queue Service), enabling:
     - Decoupled architecture with producers and consumers
     - Reliable message delivery with retry mechanisms
     - Ability to handle high-volume event streams
     - Dead-letter queues for failed event processing
     - Batch processing for improved efficiency
   - **Stateless Architecture**: Each request processes independently, making it horizontally scalable
   - **Cloud Deployment**: Deploy on a IaaS service such as AWS Fargate for serverless container execution with automatic scaling
   - **CI/CD Pipeline**: Implement cloud-based CI/CD (e.g., GitHub Actions, GitLab CI, or AWS CodePipeline) for automated testing, building, and deployment
   - **Benefits**: 
     - No server management overhead
     - Automatic scaling based on demand
     - Pay-per-use cost model
     - High availability and fault tolerance
     - Easy integration with other cloud services (S3 for file storage, CloudWatch for monitoring, SQS for event queuing, etc.)

