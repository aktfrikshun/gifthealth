# GiftHealth Copilot Instructions

## Project Context

This is a **Rails 8 pharmacy prescription management system** with database persistence, REST API, and web UI. Started as a CLI tool (main branch), evolved to full Rails app (rails branch). Core domain: tracking prescription events (created/filled/returned) and calculating pharmacy income.

## Architecture Overview

**Hybrid Rails + Service-Oriented Design:**
- **Models** (`app/models/`): ActiveRecord domain objects (Patient, Prescription)
- **Services** (`app/services/`): Business logic isolated from Rails (PrescriptionEventProcessor, FileParserService, RxNormService)
- **Controllers**: Thin orchestration layer - delegate to services
- **CLI** (`bin/prescription_processor`, `app/handlers/cli.rb`): Original interface still functional

**Key Pattern**: Business logic lives in service objects, not models or controllers. Models handle persistence and validations only.

## Critical Domain Rules

**Prescription Event Processing:**
1. **MUST create before fill/return** - fills/returns before creation are silently ignored
2. **Returns cancel fills** - cannot return more than filled (`return_count <= fill_count`)
3. **Income calculation**: `(net_fills × $5) - (return_count × $1)` where `net_fills = fill_count - return_count`
4. **Idempotency**: Multiple "created" events for same patient-drug combo are safe

**Database Constraints:**
- Patient names must be unique (unique index)
- One prescription per patient-drug combination (compound unique index on `[patient_id, drug_name]`)
- Foreign key from prescriptions to patients (referential integrity)

## Development Commands

```bash
# Setup
bundle install
rake db:create db:migrate

# Run web server
rails s                    # http://localhost:3000

# Run tests (73 specs)
rspec                      # All tests
rspec spec/models/         # Model tests only
rspec spec/features/crud_spec.rb  # CRUD operations

# Code quality
rubocop                    # Style checker (0 offenses expected)
rubocop -a                 # Auto-fix offenses
bundle audit               # Security vulnerabilities
brakeman                   # Rails security scanner

# CLI still works
./bin/prescription_processor spec/fixtures/sample_input.txt
cat data.txt | ./bin/prescription_processor

# Database management
rake db:reset              # Drop, create, migrate, seed
rake db:migrate:status     # Check migration status
```

## Testing Patterns

**FactoryBot Traits** - Use extensively for test data:
```ruby
# Prescriptions
build(:prescription)                          # Not created
build(:prescription, :created)                # Created but not filled
build(:prescription, :with_fills, fill_count: 3)  # Created + 3 fills
build(:prescription, :with_returns, return_count: 1)  # Has returns

# Patients
build(:patient)                               # No prescriptions
build(:patient, :with_prescriptions, prescription_count: 2)  # Multiple Rxs
```

**WebMock for RxNorm API** - Always stub external API calls:
```ruby
stub_request(:get, /rxnav.nlm.nih.gov/)
  .to_return(status: 200, body: mock_response.to_json)
```

**Database Cleaner Strategy:**
- Transaction strategy (fast) for unit tests
- Truncation strategy for integration tests (`:type => :integration`)

**Test Organization:**
- `spec/models/` - Model validations and relationships
- `spec/services/` - Business logic (service objects)
- `spec/features/` - CRUD workflows
- `spec/integration_spec.rb` - End-to-end with CLI
- `spec/performance_spec.rb` - Load testing (1000+ events)

## File Formats & Parsing

**FileParserService** handles multiple upload formats:
- **CSV**: Standard comma-delimited
- **TXT**: Space-delimited (original format)
- **Excel**: XLS, XLSX (via `roo` gem)

All formats must have 3 columns: `patient_name drug_name event_name`

## External Integrations

**NIH RxNorm API** (`RxNormService`):
- **Endpoint**: `https://rxnav.nlm.nih.gov/REST`
- **No API key required** (free NIH service)
- **Methods**:
  - `autocomplete(query, limit:)` - Type-ahead search (~150k drugs)
  - `validate_drug(name)` - Check if drug exists
  - `get_rxcui(name)` - Get RxNorm Concept Unique ID
- **Always mock in tests** - Use WebMock stubs
- **Timeout**: 5s open, 10s read

**Frontend Integration** (Stimulus controller):
```javascript
// app/javascript/controllers/drug_autocomplete_controller.js
// Debounced search (300ms), keyboard navigation, escape to cancel
```

## Asset Management

**Sprockets Issue (FIXED)**: The `app/assets/images/` directory MUST exist even if empty - Sprockets `link_tree` directive fails otherwise. Keep `.keep` file.

```javascript
// app/assets/config/manifest.js
//= link_tree ../images        # Requires images/ directory
//= link_directory ../stylesheets .css
//= link_tree ../../javascript .js
//= link_tree ../builds
```

## GitHub Codespaces Configuration

**CSRF Protection**: Development environment configured for Codespaces:
```ruby
# config/environments/development.rb
config.hosts << /[a-z0-9-]+\.app\.github\.dev/  # Allow Codespaces URLs
config.action_controller.forgery_protection_origin_check = false  # Disable origin check
```

This fixes `ActionController::InvalidAuthenticityToken` errors when form submissions send `localhost:3000` origin but Rails sees the Codespaces URL.

## Common Pitfalls

1. **Income calculation confusion**: Returns cost $6 total ($5 canceled fill + $1 penalty), not just $1
2. **Fill before create**: These are silently ignored, not errors - check event ordering in tests
3. **Database constraints**: Duplicate patient names or patient-drug combos will raise `ActiveRecord::RecordInvalid`
4. **RxNorm API calls**: Always mock in tests, handle timeouts gracefully in code
5. **File uploads**: Use `FileParserService`, not direct CSV parsing - supports multiple formats
6. **Codespaces CSRF errors**: Origin header mismatch - fixed in `development.rb` with `forgery_protection_origin_check = false`

## CI/CD & Security

**4 GitHub Actions workflows** (all must pass):
- **ci.yml**: RSpec + RuboCop + PostgreSQL compatibility
- **security.yml**: bundler-audit + Brakeman + dependency review
- **codeql.yml**: Semantic code analysis (Ruby + JavaScript)
- **hipaa-compliance.yml**: PHI detection, encryption checks, audit logging verification

**⚠️ NOT HIPAA COMPLIANT** - missing authentication, encryption at rest, audit logging. See `HIPAA_COMPLIANCE.md`.

## Code Conventions

**Service Objects:**
- Single responsibility (one service per business operation)
- Class methods for stateless operations
- Instance methods when maintaining state
- Return meaningful objects, not booleans

**Controllers:**
- Keep thin - delegate to services
- Handle HTTP concerns only (status codes, redirects)
- Use strong parameters (`params.require().permit()`)

**Models:**
- Validations and associations only
- No complex business logic
- Use scopes for common queries

**Naming:**
- Services: `VerbNounService` (e.g., `FileParserService`, `RxNormService`)
- Event processors: `EntityEventProcessor` (e.g., `PrescriptionEventProcessor`)

## Documentation

**Markdown with syntax highlighting** - Use Redcarpet + Rouge for rendering:
```ruby
# In controller
markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, ...)
@content = markdown.render(file_content)
```

**Key docs** (all in `documents/`):
- `REQUIREMENTS.md` - Original business requirements
- `RAILS_BRANCH_CHANGES.md` - CLI → Rails transformation guide
- `API_DOCUMENTATION.md` - REST API reference
- `HIPAA_COMPLIANCE.md` - Security and compliance requirements
- `SOLID_PRINCIPLES.md` - Design principles applied
- `TECHNOLOGY_CHOICES.md` - Ruby/Rails rationale

## Performance Notes

**In-memory (main branch)**: ~200,000 events/second  
**Database (rails branch)**: ~100-250 events/second  

Trade-off: 90x slower but persistent, ACID-compliant, queryable.

**Optimization paths** (if needed):
1. Use `insert_all` for batch operations
2. Switch to PostgreSQL (better write concurrency than SQLite)
3. Add Redis caching for read-heavy operations
4. Background jobs (Sidekiq) for file processing
5. Connection pooling for concurrent requests

## Routes Structure

```ruby
# Web UI
root 'prescriptions#index'                    # Dashboard
/prescriptions                                 # CRUD operations
/patients                                      # Patient management
/documents/:name                               # Markdown viewer

# REST API
POST /api/v1/prescription_events               # Single event
POST /api/v1/prescription_events/batch         # Bulk events
GET  /api/v1/drugs/autocomplete?query=...      # Drug search
GET  /api/v1/drugs/validate?name=...           # Drug validation
```

## When Making Changes

**Always:**
1. Run full test suite (`rspec`) before committing
2. Check code style (`rubocop`)
3. Update relevant documentation if changing APIs or domain logic
4. Add/update FactoryBot factories for new models
5. Mock external API calls in tests

**For new features:**
1. Start with service object if business logic
2. Add controller/route if web/API interface needed
3. Keep models focused on persistence
4. Write integration test covering happy path
5. Add factory traits for common test scenarios

**For bug fixes:**
1. Write failing test first (TDD)
2. Fix in service layer if business logic issue
3. Fix in controller if HTTP/params handling issue
4. Verify all related tests still pass
