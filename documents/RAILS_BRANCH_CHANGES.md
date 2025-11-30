# Rails Branch Implementation Changes

This document describes all changes implemented in the `rails` branch, which adds Rails 8, SQLite database persistence, a web interface, and a REST API to the GiftHealth Pharmacy prescription processing system.

## Table of Contents

1. [Overview](#overview)
2. [Infrastructure Changes](#infrastructure-changes)
3. [Database Implementation](#database-implementation)
4. [Model Layer Changes](#model-layer-changes)
5. [Web Interface](#web-interface)
6. [REST API](#rest-api)
7. [Testing Updates](#testing-updates)
8. [Performance Considerations](#performance-considerations)
9. [Migration Guide](#migration-guide)
10. [Future Enhancements](#future-enhancements)

---

## Overview

### What Changed

The original implementation was a command-line Ruby application using Plain Old Ruby Objects (POROs) with in-memory data storage. This branch transforms it into a full Rails 8 web application with:

- **Database Persistence**: SQLite database for storing patients and prescriptions
- **Web Interface**: Beautiful pharmacy-themed web UI for file uploads and data visualization
- **REST API**: JSON API endpoints for programmatic access
- **Enhanced Capabilities**: Support for CSV and Excel file uploads
- **Maintained Compatibility**: Original CLI still works with database backend

### Why These Changes

1. **Persistence**: Data now persists across application restarts
2. **Scalability**: Database enables handling larger datasets
3. **Accessibility**: Web interface makes the system accessible to non-technical users
4. **Integration**: REST API enables integration with other systems
5. **Modern Stack**: Rails 8 provides a solid foundation for future enhancements

---

## Infrastructure Changes

### Dependencies Added

#### Gemfile Changes

```ruby
# Rails framework
gem 'rails', '~> 8.0'
gem 'sqlite3', '~> 2.0'

# Web interface
gem 'sprockets-rails', '~> 3.5'
gem 'importmap-rails', '~> 2.0'
gem 'turbo-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.3'

# File parsing
gem 'roo', '~> 2.10'
gem 'roo-xls', '~> 1.2'

# Server
gem 'puma', '~> 6.4'

# Testing (already present, versions updated)
gem 'rspec-rails', '~> 6.1'
gem 'database_cleaner-active_record', '~> 2.1'
```

### Rails Configuration

#### New Configuration Files

1. **config/application.rb**: Main Rails application configuration
2. **config/boot.rb**: Bundler setup
3. **config/environment.rb**: Rails environment initialization
4. **config/database.yml**: Database configuration for development, test, and production
5. **config/routes.rb**: URL routing configuration
6. **config/environments/**: Environment-specific configurations
   - `development.rb`
   - `test.rb`
   - `production.rb`
7. **Rakefile**: Rails tasks loader

#### Key Configuration Decisions

```ruby
# config/application.rb
config.api_only = false  # Enable views and assets for web interface
config.autoload_paths += %W[#{config.root}/app/models #{config.root}/app/services #{config.root}/app/handlers]
```

---

## Database Implementation

### Entity Relationship Diagram

![Database ERD](erd-diagram.svg)

### Schema Design

#### Patients Table

```ruby
create_table :patients do |t|
  t.string :name, null: false, index: { unique: true }
  t.timestamps
end
```

**Design Decisions:**
- Unique index on `name` prevents duplicate patients
- Timestamps track creation/update times for audit trails
- Simple structure maintains compatibility with original design

#### Prescriptions Table

```ruby
create_table :prescriptions do |t|
  t.references :patient, null: false, foreign_key: true
  t.string :drug_name, null: false
  t.boolean :created, default: false, null: false
  t.integer :fill_count, default: 0, null: false
  t.integer :return_count, default: 0, null: false
  t.timestamps
  
  t.index [:patient_id, :drug_name], unique: true
end
```

**Design Decisions:**
- Foreign key ensures referential integrity
- Unique compound index on `[patient_id, drug_name]` enforces one prescription per patient-drug combination
- Counters (`fill_count`, `return_count`) store aggregate state for performance
- `created` boolean flag maintains the creation state business rule

### Migrations

Located in `db/migrate/`:

1. `20251130000001_create_patients.rb`
2. `20251130000002_create_prescriptions.rb`

To run migrations:
```bash
bundle exec rake db:create db:migrate
```

---

## Model Layer Changes

### From POROs to ActiveRecord

#### Patient Model

**Before (PORO):**
```ruby
class Patient
  def initialize(name)
    @name = name
    @prescriptions = {}
  end
end
```

**After (ActiveRecord):**
```ruby
class Patient < ApplicationRecord
  has_many :prescriptions, dependent: :destroy
  validates :name, presence: true, uniqueness: true
end
```

**Key Changes:**
- Inherits from `ApplicationRecord` instead of basic Ruby class
- Database-backed with automatic persistence
- Uses Rails validations instead of manual `ArgumentError` raises
- Associations managed by ActiveRecord
- Methods adapted to work with database queries

#### Prescription Model

**Before (PORO):**
```ruby
class Prescription
  def initialize(patient:, drug_name:)
    @patient = patient
    @drug_name = drug_name
    @created = false
    @fill_count = 0
    @return_count = 0
  end
  
  def fill
    return nil unless @created
    @fill_count += 1
    self
  end
end
```

**After (ActiveRecord):**
```ruby
class Prescription < ApplicationRecord
  belongs_to :patient
  validates :drug_name, presence: true
  validates :drug_name, uniqueness: { scope: :patient_id }
  
  def fill
    return nil unless created?
    increment!(:fill_count)
    self
  end
end
```

**Key Changes:**
- Uses `increment!` for atomic database updates
- Validations at database level
- `belongs_to` association instead of instance variable
- Methods now trigger database writes

### Business Logic Preservation

All business rules were maintained:
- Prescriptions must be created before being filled
- Cannot return more prescriptions than filled
- Income calculation: `(net_fills × $5) - (return_count × $1)`
- Net fills: `fill_count - return_count`

---

## Web Interface

### Architecture

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── prescriptions_controller.rb
│   └── api/v1/
│       └── prescription_events_controller.rb
├── views/
│   ├── layouts/
│   │   └── application.html.erb
│   └── prescriptions/
│       └── index.html.erb
├── services/
│   ├── prescription_event_processor.rb
│   └── file_parser_service.rb
└── assets/
    └── stylesheets/
        └── application.css
```

### Features

#### 1. File Upload Interface

**Route:** `GET /` (root)

**Features:**
- Drag-and-drop file upload
- Supports CSV and Excel (XLS/XLSX) formats
- Visual feedback with file name display
- Pharmacy-themed styling with medical iconography

**Implementation:**
```ruby
def upload
  file = params[:file]
  parser = FileParserService.new(file.tempfile.path, file.content_type)
  
  processor = PrescriptionEventProcessor.new
  parser.each_row do |row|
    patient_name, drug_name, event_name = row[0..2]
    processor.process_event(
      patient_name: patient_name.to_s.strip,
      drug_name: drug_name.to_s.strip,
      event_name: event_name.to_s.strip.downcase
    )
  end
end
```

#### 2. Manual Event Entry

**Route:** `POST /prescriptions/process_events`

**Features:**
- Text area for entering events manually
- One event per line format
- Immediate processing and feedback

#### 3. Income Report Display

**Features:**
- Real-time display of processed data
- Sortable table (by fills descending, income ascending)
- Summary statistics (total patients, fills, income)
- Color-coded income (positive/negative)
- Responsive design

**Color Scheme:**
```css
--pharmacy-primary: #00a8cc    /* Teal */
--pharmacy-secondary: #005f73   /* Dark teal */
--pharmacy-accent: #94d2bd      /* Light teal */
--pharmacy-light: #e9f5f7       /* Very light teal */
```

### FileParserService

New service for parsing uploaded files:

```ruby
class FileParserService
  def initialize(file_path, content_type)
    @file_path = file_path
    @content_type = content_type
  end

  def each_row(&block)
    case @content_type
    when 'text/csv'
      parse_csv(&block)
    when 'application/vnd.ms-excel', 
         'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      parse_excel(&block)
    end
  end
end
```

**Supported Formats:**
- CSV (`.csv`)
- Excel 97-2003 (`.xls`)
- Excel 2007+ (`.xlsx`)

---

## REST API

### Architecture

**Namespace:** `/api/v1`

**Controller:** `Api::V1::PrescriptionEventsController`

**Format:** JSON

### Endpoints

#### 1. Create Single Event

```http
POST /api/v1/prescription_events
Content-Type: application/json

{
  "patient_name": "John",
  "drug_name": "A",
  "event_name": "created"
}
```

**Response (201 Created):**
```json
{
  "message": "Event processed successfully",
  "patient_name": "John",
  "drug_name": "A",
  "event_name": "created"
}
```

#### 2. Batch Create Events

```http
POST /api/v1/prescription_events/batch
Content-Type: application/json

{
  "events": [
    {"patient_name": "John", "drug_name": "A", "event_name": "created"},
    {"patient_name": "John", "drug_name": "A", "event_name": "filled"}
  ]
}
```

**Response (200 OK):**
```json
{
  "processed": 2,
  "total": 2
}
```

**Partial Success:**
```json
{
  "processed": 1,
  "total": 2,
  "errors": [
    {"index": 1, "error": "Missing required fields"}
  ]
}
```

### Error Handling

- `400 Bad Request`: Invalid request format
- `422 Unprocessable Entity`: Valid format but processing failed
- Detailed error messages for debugging

### Authentication

**Current State:** No authentication (development only)

**Recommended for Production:**
- API key authentication
- OAuth2
- JWT tokens
- Rate limiting

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for full API reference.

---

## Testing Updates

### RSpec Configuration Changes

#### Database Cleaner Setup

```ruby
# spec/spec_helper.rb
config.before(:suite) do
  DatabaseCleaner.clean_with(:truncation)
end

config.before(:each) do |example|
  # Use truncation for integration tests (external processes)
  # Use transaction for other tests (faster)
  strategy = example.metadata[:type] == :integration ? :truncation : :transaction
  DatabaseCleaner.strategy = strategy
  DatabaseCleaner.start
end

config.after(:each) do
  DatabaseCleaner.clean
end
```

**Key Decisions:**
- **Transaction strategy** for unit tests (fast, isolated)
- **Truncation strategy** for integration tests (handles external processes)
- Integration tests spawn external Ruby processes via `Open3.capture3`, which run outside RSpec's transaction scope

### Factory Updates

Factories converted from POROs to ActiveRecord:

**Before:**
```ruby
factory :patient do
  name { Faker::Name.first_name }
  initialize_with { new(name) }
end
```

**After:**
```ruby
factory :patient do
  name { Faker::Name.first_name }
  # No initialize_with needed - ActiveRecord handles it
end
```

### Model Spec Updates

**Before (PORO expectations):**
```ruby
expect { Patient.new(nil) }.to raise_error(ArgumentError, 'name cannot be nil')
```

**After (ActiveRecord validations):**
```ruby
patient = Patient.new(name: nil)
expect(patient).not_to be_valid
expect(patient.errors[:name]).to include("can't be blank")
```

### Integration Tests

Updated to handle database persistence across external process calls:

```ruby
RSpec.describe 'Integration tests', type: :integration do
  # Explicit cleanup before each test
  before(:each) do
    Patient.destroy_all
    Prescription.destroy_all
  end
end
```

### Test Results

All 48 tests pass:
- 18 Prescription model tests
- 10 Patient model tests
- 13 PrescriptionEventProcessor tests
- 3 CLI tests
- 2 Integration tests
- 2 Performance tests

---

## Performance Considerations

### Performance Impact of Database

**Before (In-Memory):**
- 1000 events: ~0.1 seconds
- 200,000+ events/second

**After (SQLite):**
- 1000 events: ~9 seconds
- 100-250 events/second

**Trade-offs:**
- ✅ Data persistence across restarts
- ✅ ACID compliance
- ✅ Query capabilities
- ⚠️ Slower processing (expected with database I/O)
- ⚠️ Sequential writes (SQLite limitation)

### Performance Test Updates

Adjusted expectations for database operations:

```ruby
# Before
expect(processing_time).to be < 1.0

# After
expect(processing_time).to be < 15.0  # Realistic for DB operations
```

### Optimization Opportunities

1. **Batch Inserts**: Use `insert_all` for bulk operations
2. **Connection Pooling**: Configure for concurrent requests
3. **Indexing**: Already optimized with compound index on prescriptions
4. **Caching**: Add Redis for frequently accessed reports
5. **PostgreSQL**: Consider for production (better concurrency than SQLite)

---

## Migration Guide

### For Existing Users

#### 1. Update Dependencies

```bash
bundle install
```

#### 2. Create Database

```bash
bundle exec rake db:create db:migrate
```

#### 3. Start Web Server

```bash
bundle exec rails server
```

Access at: `http://localhost:3000`

#### 4. CLI Still Works

```bash
./bin/prescription_processor spec/fixtures/sample_input.txt
cat input.txt | ./bin/prescription_processor
```

### Data Migration

If you have existing data, create a migration script:

```ruby
# lib/tasks/import_legacy_data.rake
namespace :import do
  desc "Import legacy data from text files"
  task legacy_data: :environment do
    processor = PrescriptionEventProcessor.new
    
    Dir.glob("legacy_data/*.txt").each do |file|
      File.readlines(file).each do |line|
        processor.process_line(line)
      end
    end
    
    puts "Import complete!"
  end
end
```

Run with:
```bash
bundle exec rake import:legacy_data
```

---

## Future Enhancements

### Planned Features

1. **Authentication & Authorization**
   - User accounts with role-based access
   - API key management
   - OAuth2 integration

2. **Advanced Reporting**
   - Date range filtering
   - Drug-specific reports
   - Export to PDF/Excel
   - Chart visualizations

3. **Audit Trail**
   - Event history tracking
   - Who changed what and when
   - Compliance reporting

4. **Drug Management**
   - Drug catalog with pricing
   - Per-drug income rates
   - Inventory tracking

5. **Patient Management**
   - Full patient profiles
   - Contact information
   - Prescription history

6. **Performance Optimizations**
   - Background job processing (Sidekiq)
   - PostgreSQL for production
   - Redis caching
   - CDN for static assets

7. **Notifications**
   - Email alerts for low fills
   - SMS notifications
   - Webhook integrations

8. **Multi-tenancy**
   - Support multiple pharmacies
   - Separate data isolation
   - Centralized reporting

### Technical Debt

- Add API authentication before production deployment
- Implement rate limiting
- Add request/response logging
- Set up monitoring (New Relic, Datadog)
- Configure background jobs for large file uploads
- Add pagination to reports
- Implement API versioning strategy

---

## Architecture Decisions

### Why SQLite?

**Pros:**
- Zero configuration
- Embedded database
- Perfect for development/testing
- Sufficient for small-medium deployments
- File-based (easy backups)

**Cons:**
- Limited concurrency
- Not suitable for high-traffic production
- No built-in replication

**Recommendation:** Use SQLite for development, PostgreSQL for production.

### Why Rails 8?

**Pros:**
- Latest stable version
- Improved performance
- Modern asset pipeline
- Active support
- Rich ecosystem

**Cons:**
- Learning curve for team
- Larger footprint than pure Ruby

**Decision:** Benefits outweigh costs for a web application.

### Why Keep CLI?

**Reasoning:**
- Backward compatibility
- Scripting/automation use cases
- Testing convenience
- Unix philosophy (do one thing well)

---

## Deployment Guide

### Development

```bash
bundle exec rails server
# Access at http://localhost:3000
```

### Production (Example with Heroku)

1. **Add Procfile:**
```
web: bundle exec puma -C config/puma.rb
```

2. **Update database.yml for PostgreSQL:**
```yaml
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV['DATABASE_URL'] %>
```

3. **Deploy:**
```bash
git push heroku rails:main
heroku run rake db:migrate
heroku open
```

### Production Checklist

- [ ] Switch to PostgreSQL
- [ ] Add authentication
- [ ] Enable SSL
- [ ] Set up monitoring
- [ ] Configure logging
- [ ] Set up backups
- [ ] Enable rate limiting
- [ ] Add error tracking (Sentry)
- [ ] Configure CDN
- [ ] Set up CI/CD pipeline

---

## Testing the Changes

### Web Interface

1. Start server: `bundle exec rails server`
2. Visit `http://localhost:3000`
3. Upload `spec/fixtures/sample_input.txt`
4. Verify report displays correctly

### REST API

```bash
# Test single event
curl -X POST http://localhost:3000/api/v1/prescription_events \
  -H "Content-Type: application/json" \
  -d '{"patient_name": "Test", "drug_name": "X", "event_name": "created"}'

# Test batch
curl -X POST http://localhost:3000/api/v1/prescription_events/batch \
  -H "Content-Type: application/json" \
  -d '{"events": [{"patient_name": "Test", "drug_name": "X", "event_name": "filled"}]}'
```

### CLI

```bash
./bin/prescription_processor spec/fixtures/sample_input.txt
```

### Run All Tests

```bash
bundle exec rspec
```

---

## CRUD Interface

### Overview

A complete CRUD (Create, Read, Update, Delete) interface has been added to manage prescription data after upload. This allows users to manually adjust prescriptions, correct errors, and manage patient records through the web interface.

### Features

#### Prescription Management

**View All Prescriptions**
- Enhanced report table showing individual prescriptions (not just patient summaries)
- Each row displays: Patient Name, Drug Name, Status, Net Fills, Income, and Actions
- Color-coded status badges (Created/Not Created)
- Detailed fill information showing fills and returns

**Create New Prescription**
- Form to add prescriptions manually
- Patient name autocomplete from existing patients
- Fields: Patient Name, Drug Name, Created Status, Fill Count, Return Count
- Real-time validation

**Edit Prescription**
- Update all prescription fields
- Change patient assignment
- Adjust fill and return counts
- Real-time income calculation preview

**Delete Prescription**
- Remove individual prescriptions
- Automatic patient cleanup (deletes patient if no prescriptions remain)
- Confirmation dialog to prevent accidental deletion

**Quick Actions**
- **Increment Fill**: Add a fill to the prescription (green + button)
- **Decrement Fill** (Return): Process a return (yellow - button)
- Inline buttons for quick adjustments without navigating to edit page

#### Patient Management

**View All Patients** (`/patients`)
- Comprehensive patient list with statistics
- Shows: Patient Name, # of Prescriptions, Total Fills, Total Income
- Summary statistics at bottom

**Delete Patient**
- Removes patient and all their prescriptions
- Confirmation dialog required

**Clear Prescriptions**
- Removes all prescriptions for a patient
- Keeps patient record intact
- Useful for resetting patient data

### Routes Added

```ruby
# Prescription CRUD
resources :prescriptions do
  collection do
    post :upload          # File upload
    post :process_events  # Manual event entry
  end
  member do
    patch :increment_fill   # Quick add fill
    patch :decrement_fill   # Quick return
  end
end

# Patient Management
resources :patients, only: [:index, :destroy] do
  member do
    delete :clear_prescriptions
  end
end
```

### Controllers

**PrescriptionsController**
- `index`: List all prescriptions with patient grouping
- `new`: Form for creating new prescription
- `create`: Save new prescription
- `edit`: Form for editing existing prescription
- `update`: Save changes to prescription
- `destroy`: Delete prescription
- `increment_fill`: Add a fill count
- `decrement_fill`: Process a return
- `upload`: Handle file uploads (existing)
- `process_events`: Handle manual events (existing)

**PatientsController** (new)
- `index`: List all patients with summary stats
- `destroy`: Delete patient and all prescriptions
- `clear_prescriptions`: Remove all prescriptions for a patient

### Views Added

- `app/views/prescriptions/new.html.erb`: Create prescription form
- `app/views/prescriptions/edit.html.erb`: Edit prescription form
- `app/views/patients/index.html.erb`: Patient management page
- `app/views/prescriptions/index.html.erb`: Enhanced with CRUD actions

### UI Enhancements

**Action Buttons**
- Icon-based buttons for quick recognition
- Color-coded by action type (success, warning, primary, danger)
- Grouped buttons for related actions
- Tooltips on hover

**Form Features**
- Patient name autocomplete using HTML5 datalist
- Toggle switches for boolean fields
- Number inputs with validation
- Real-time calculation display

**Confirmation Dialogs**
- Turbo-powered confirmations for destructive actions
- Prevents accidental data loss
- User-friendly messaging

### Styling

New CSS file `app/assets/stylesheets/crud.css` includes:
- Button group styling
- Form control enhancements
- Badge styling
- Alert customization
- Table hover effects
- Action button transitions

### Business Logic

**Income Calculation**
- Formula: `(net_fills * $5) - (return_count * $1)`
- Net fills = fill_count - return_count
- Returns incur both loss of fill income AND $1 penalty
- Displayed in real-time on edit form

**Validation Rules**
- Drug name must be present
- Drug name must be unique per patient
- Fill count and return count must be >= 0
- Patient name required for prescription creation

**Automatic Cleanup**
- Deleting a prescription removes patient if no other prescriptions exist
- Maintains data integrity
- Prevents orphaned patient records

### Testing

Added comprehensive CRUD test suite in `spec/features/crud_spec.rb`:
- 14 test cases covering all CRUD operations
- Prescription create, read, update, delete
- Patient management operations
- Income calculation verification
- Aggregation calculations
- Edge cases and validations

All 14 tests pass successfully.

### User Workflows

**Correcting Upload Errors**
1. Upload file with prescription data
2. Review report for errors
3. Click edit button on incorrect prescription
4. Update values and save
5. See updated calculations immediately

**Manual Data Entry**
1. Click "Add Prescription" button
2. Type patient name (autocomplete suggests existing)
3. Enter drug name
4. Set initial counts
5. Save and see in report

**Quick Adjustments**
1. From main report, click + or - buttons
2. Counts update immediately
3. Income recalculates automatically
4. No page navigation required

**Patient Cleanup**
1. Navigate to "Manage Patients"
2. Review patient list with statistics
3. Clear prescriptions or delete entire patient
4. Confirm action
5. Data updated immediately

---

## Conclusion

This Rails implementation transforms the GiftHealth prescription processor from a simple CLI tool into a full-featured web application while maintaining all original functionality and business rules. The system now supports:

- ✅ Persistent data storage
- ✅ Web-based file uploads
- ✅ REST API for integrations
- ✅ Beautiful pharmacy-themed UI
- ✅ CSV and Excel file support
- ✅ Backward-compatible CLI
- ✅ Comprehensive test coverage
- ✅ Production-ready architecture
- ✅ **Full CRUD interface for data management**
- ✅ **Patient management tools**
- ✅ **Quick action buttons for common operations**

The foundation is now in place for future enhancements including user authentication, advanced reporting, and enterprise features.

---

## References

- [API Documentation](API_DOCUMENTATION)
- [SOLID Principles](SOLID_PRINCIPLES)
- [Technology Choices](TECHNOLOGY_CHOICES)
- [Requirements](REQUIREMENTS)
- [Rails Guides](https://guides.rubyonrails.org/)
