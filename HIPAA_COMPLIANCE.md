# HIPAA Compliance Guide for GiftHealth

This document outlines HIPAA (Health Insurance Portability and Accountability Act) compliance requirements and implementation guidelines for the GiftHealth Pharmacy prescription processing system.

## ⚠️ Current HIPAA Status

**COMPLIANCE STATUS: NOT HIPAA COMPLIANT**

This application is currently a **development/demonstration system** and is **NOT suitable for production use with real PHI** until the following critical requirements are implemented.

## What is PHI?

Protected Health Information (PHI) includes:
- Patient names
- Prescription information
- Medical record numbers
- Social Security numbers
- Email addresses
- Phone numbers
- Dates of birth
- Any data that can identify a patient

**Current PHI in System:**
- ✅ Patient names
- ✅ Prescription drug names
- ✅ Fill counts and financial data

## Critical HIPAA Requirements (Not Yet Implemented)

### 🔴 HIGH PRIORITY - Required Before Production

#### 1. Authentication & Authorization
**Status:** ❌ NOT IMPLEMENTED

**Requirements:**
- User authentication required for all access
- Role-based access control (RBAC)
- Multi-factor authentication (MFA) for administrative access
- Automatic session timeout (15 minutes idle)
- Password complexity requirements
- Account lockout after failed attempts

**Implementation Plan:**
```ruby
# Add to Gemfile
gem 'devise'                    # Authentication
gem 'devise-two-factor'         # MFA
gem 'pundit'                    # Authorization
gem 'devise-security'           # Password policies
```

**Recommended Roles:**
- Administrator: Full access
- Pharmacist: View/edit prescriptions
- Technician: View only
- Auditor: Read-only access to logs

#### 2. Encryption
**Status:** ⚠️ PARTIAL

**Requirements:**
- ✅ Data in transit (HTTPS/TLS) - Configured for production
- ❌ Data at rest (database encryption) - NOT IMPLEMENTED
- ❌ Backup encryption - NOT IMPLEMENTED
- ❌ Application-level encryption for sensitive fields

**Implementation Plan:**
```ruby
# Database encryption (SQLite)
gem 'sqlcipher'

# Field-level encryption
gem 'attr_encrypted'
gem 'lockbox'

# Example: Encrypt patient names
class Patient < ApplicationRecord
  encrypts :name, deterministic: true
end
```

**Production Database:**
- Switch from SQLite to PostgreSQL with encryption
- Enable TLS for database connections
- Use encrypted RDS or managed database service

#### 3. Audit Logging
**Status:** ❌ NOT IMPLEMENTED

**Requirements:**
- Log all PHI access (who, what, when, where)
- Log all modifications to PHI
- Log authentication events (login, logout, failures)
- Log authorization failures
- Tamper-proof audit logs
- Retain logs for 6+ years

**Implementation Plan:**
```ruby
# Add to Gemfile
gem 'paper_trail'         # Audit trail for models
gem 'lograge'            # Structured logging
gem 'audited'            # Alternative audit solution

# Example implementation
class Patient < ApplicationRecord
  has_paper_trail
end

class Prescription < ApplicationRecord
  has_paper_trail
end

# Log API access
class ApiController < ApplicationController
  after_action :log_phi_access
  
  def log_phi_access
    AuditLog.create(
      user: current_user,
      action: action_name,
      resource: controller_name,
      timestamp: Time.current,
      ip_address: request.remote_ip
    )
  end
end
```

#### 4. Access Controls
**Status:** ❌ NOT IMPLEMENTED

**Requirements:**
- API endpoints require authentication
- No public access to PHI
- Minimum necessary access (least privilege)
- Regular access reviews
- Automatic access revocation on termination

**Current Issues:**
- ❌ REST API has NO authentication
- ❌ Web interface accessible without login
- ❌ No session management
- ❌ No IP whitelisting

**Implementation Plan:**
```ruby
# Require authentication for all controllers
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end

# API authentication
class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_user!
  
  private
  
  def authenticate_api_user!
    # Use API keys, OAuth, or JWT
    authenticate_or_request_with_http_token do |token, options|
      ApiKey.active.exists?(token: token)
    end
  end
end

# Rate limiting
gem 'rack-attack'

# config/initializers/rack_attack.rb
Rack::Attack.throttle('api/ip', limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/api')
end
```

#### 5. Data Backup & Recovery
**Status:** ❌ NOT IMPLEMENTED

**Requirements:**
- Automated daily backups
- Encrypted backup storage
- Tested recovery procedures
- Offsite backup storage
- Backup retention policy (7 years recommended)

**Implementation Plan:**
```bash
# Automated RDS backup (built-in)
# Enable in RDS console or via Terraform:

resource "aws_db_instance" "main" {
  identifier = "gifthealth-db"
  
  # Automated backups
  backup_retention_period = 35  # 35 days
  backup_window          = "03:00-04:00"
  
  # Encryption at rest (required for HIPAA)
  storage_encrypted = true
  kms_key_id       = aws_kms_key.rds.arn
  
  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  # High availability
  multi_az = true
}

# Long-term backup to S3
resource "aws_s3_bucket" "backups" {
  bucket = "gifthealth-hipaa-backups"
  
  versioning {
    enabled = true
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3.arn
      }
    }
  }
  
  lifecycle_rule {
    enabled = true
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    expiration {
      days = 2555  # 7 years
    }
  }
}
```

### 🟡 MEDIUM PRIORITY - Required for Full Compliance

#### 6. Business Associate Agreements (BAA)

**Requirements:**
- Sign BAA with all third-party vendors
- Document all data sharing
- Regular vendor security reviews

**Vendors Requiring BAA:**
- Cloud hosting provider (AWS - sign BAA in console)
- Database service (Amazon RDS - HIPAA-eligible)
- Backup storage (Amazon S3 - HIPAA-eligible)
- Log storage (CloudWatch Logs - HIPAA-eligible)
- Email service (Amazon SES with BAA, or SendGrid)
- Analytics service (if used - verify HIPAA compliance)
- Error tracking (Sentry with BAA, or AWS X-Ray)
- Payment processor (if handling payments)

**AWS Services Eligible for HIPAA:**
- Amazon ECS (Fargate)
- Amazon RDS (PostgreSQL)
- Amazon S3 (with encryption)
- Amazon EBS (encrypted volumes)
- AWS Secrets Manager
- Amazon CloudWatch
- Amazon VPC
- AWS Certificate Manager
- Elastic Load Balancing
- Amazon ElastiCache (Redis)
- Amazon SES
- AWS Lambda
- Amazon SNS/SQS

#### 7. Incident Response Plan

**Requirements:**
- Written incident response procedures
- Designated security officer
- Breach notification procedures (60 days)
- Regular incident response drills

**Template:** See `INCIDENT_RESPONSE.md`

#### 8. Risk Assessment

**Requirements:**
- Annual security risk assessment
- Document identified risks
- Mitigation plans for each risk
- Regular reassessment

**Risk Assessment Areas:**
- Physical security
- Network security
- Application security
- Access controls
- Data backup/recovery
- Incident response
- Workforce training

#### 9. Security Training

**Requirements:**
- All workforce members must complete HIPAA training
- Annual refresher training
- Document training completion
- Role-specific training

**Training Topics:**
- HIPAA Privacy Rule
- HIPAA Security Rule
- PHI handling procedures
- Incident reporting
- Password security
- Social engineering awareness

### 🟢 ONGOING REQUIREMENTS

#### 10. Data Retention & Disposal

**Requirements:**
- Document retention policies
- Automated data deletion after retention period
- Secure data disposal procedures
- Patient data deletion requests (right to be forgotten)

**Implementation:**
```ruby
# lib/tasks/data_retention.rake
namespace :compliance do
  desc "Delete prescriptions older than retention period"
  task cleanup_old_records: :environment do
    retention_period = 7.years.ago
    
    old_prescriptions = Prescription.where('created_at < ?', retention_period)
    deleted_count = old_prescriptions.count
    
    old_prescriptions.destroy_all
    
    # Log the cleanup
    ComplianceLog.create(
      action: 'data_retention_cleanup',
      records_deleted: deleted_count,
      retention_date: retention_period
    )
  end
end
```

#### 11. Security Headers

**Status:** ⚠️ PARTIAL

**Implementation:**
```ruby
# Add to Gemfile
gem 'secure_headers'

# config/initializers/secure_headers.rb
SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.hsts = "max-age=31536000; includeSubDomains"
  config.csp = {
    default_src: %w('self'),
    script_src: %w('self'),
    style_src: %w('self' 'unsafe-inline'),
    img_src: %w('self' data:),
    font_src: %w('self'),
    connect_src: %w('self'),
    frame_ancestors: %w('none')
  }
end
```

## Automated Compliance Checks

### GitHub Actions Workflow

The `.github/workflows/hipaa-compliance.yml` workflow performs automated checks:

**PHI Detection:**
- Scans code for SSN patterns
- Detects medical record numbers
- Finds credit card numbers
- Identifies real email addresses in test data

**Security Controls:**
- Verifies SSL/TLS enforcement
- Checks for encryption configuration
- Validates session security
- Confirms audit logging setup

**Access Control:**
- Verifies authentication implementation
- Checks authorization setup
- Validates API authentication

**Dependency Security:**
- Scans for vulnerable gems
- OWASP dependency check
- Regular security updates

### Third-Party PHI Detection Tools

#### 1. Nightfall AI (Recommended)
**Cost:** Free tier available
**Features:**
- ML-based PHI detection
- Detects 100+ types of sensitive data
- GitHub integration
- API available

**Setup:**
```bash
# Sign up at https://nightfall.ai
# Get API key
# Add to GitHub secrets: NIGHTFALL_API_KEY

# Configure .nightfall.yml
detection_rules:
  - name: SSN
    pattern: '\b[0-9]{3}-[0-9]{2}-[0-9]{4}\b'
  - name: MRN
    pattern: '\bMRN[:\s]*[0-9]{6,}\b'
  - name: EMAIL_ADDRESS
    pattern: email
```

#### 2. GitGuardian (Alternative)
**Cost:** Free for public repos
**Features:**
- Secrets detection
- PHI detection
- Real-time scanning
- Developer-friendly

#### 3. TruffleHog (Open Source)
**Cost:** Free
**Features:**
- Scans git history for secrets
- Regex-based detection
- Entropy detection

```bash
# Install
pip install truffleHog

# Scan repository
truffleHog --regex --entropy=True .
```

## Development Best Practices

### 1. Never Use Real PHI in Development

**Test Data Guidelines:**
- Use faker gem for test data
- Patient names: John Doe, Jane Smith, etc.
- Emails: user@example.com, test@test.com
- Phones: (555) 555-5555
- No real SSNs, MRNs, or patient data

```ruby
# spec/factories/patients.rb
FactoryBot.define do
  factory :patient do
    # Use safe test names
    name { Faker::Name.first_name }
    
    # Never use real patient data
    # name { "Real Patient Name" }  # ❌ WRONG
  end
end
```

### 2. Secure Configuration Management

**Never commit:**
- API keys
- Database passwords
- Encryption keys
- SSL certificates
- OAuth tokens

**Use Rails credentials:**
```bash
# Edit encrypted credentials
EDITOR=vim rails credentials:edit

# Access in code
Rails.application.credentials.database_password
```

### 3. Code Review Checklist

Before merging code:
- [ ] No hardcoded credentials
- [ ] No real PHI in tests
- [ ] Authentication on all endpoints
- [ ] Audit logging for PHI access
- [ ] SQL injection prevention (use parameterized queries)
- [ ] XSS prevention (escape output)
- [ ] CSRF protection enabled
- [ ] Input validation implemented

### 4. Database Security

```ruby
# config/database.yml (production)
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV['DATABASE_URL'] %>
  
  # Encryption in transit
  sslmode: require
  sslcert: <%= ENV['DATABASE_SSL_CERT'] %>
  sslkey: <%= ENV['DATABASE_SSL_KEY'] %>
  sslrootcert: <%= ENV['DATABASE_SSL_ROOT_CERT'] %>
```

## Production Deployment Checklist

Before deploying to production with real PHI:

### Infrastructure
- [ ] HTTPS/TLS everywhere (SSL certificate installed)
- [ ] Database encryption at rest enabled
- [ ] Encrypted backups configured
- [ ] VPN or private network for admin access
- [ ] Firewall configured (minimal open ports)
- [ ] Intrusion detection system (IDS) enabled
- [ ] DDoS protection enabled

### Application
- [ ] User authentication implemented
- [ ] Role-based access control implemented
- [ ] API authentication implemented
- [ ] Audit logging enabled
- [ ] Session timeout configured (15 minutes)
- [ ] Password complexity enforced
- [ ] MFA enabled for admins
- [ ] Security headers configured
- [ ] CSRF protection enabled
- [ ] SQL injection prevention verified
- [ ] XSS prevention verified

### Compliance
- [ ] BAAs signed with all vendors
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] Risk assessment completed
- [ ] Incident response plan documented
- [ ] Security training completed
- [ ] Data retention policy documented
- [ ] Breach notification procedures documented

### Monitoring
- [ ] Application monitoring (New Relic, Datadog)
- [ ] Security monitoring (SIEM)
- [ ] Uptime monitoring
- [ ] Log aggregation (Splunk, ELK)
- [ ] Alerting configured
- [ ] Automated backups verified

### Documentation
- [ ] HIPAA compliance documentation
- [ ] Security policies documented
- [ ] Admin procedures documented
- [ ] Disaster recovery plan
- [ ] Incident response plan
- [ ] User access procedures

## Recommended Gems for HIPAA Compliance

```ruby
# Gemfile

# Authentication & Authorization
gem 'devise'                      # User authentication
gem 'devise-two-factor'           # MFA
gem 'devise-security'             # Password policies
gem 'pundit'                      # Authorization
gem 'cancancan'                   # Alternative authorization

# Encryption
gem 'attr_encrypted'              # Field-level encryption
gem 'lockbox'                     # Modern encryption
gem 'bcrypt'                      # Password hashing (comes with devise)

# Audit Logging
gem 'paper_trail'                 # Model versioning
gem 'audited'                     # Alternative audit trail
gem 'lograge'                     # Structured logging

# Security
gem 'secure_headers'              # Security headers
gem 'rack-attack'                 # Rate limiting
gem 'brakeman'                    # Security scanner

# Session Management
gem 'redis'                       # Session store
gem 'redis-rails'                 # Redis session store

# API Security
gem 'doorkeeper'                  # OAuth provider
gem 'jwt'                         # JSON Web Tokens
gem 'rack-cors'                   # CORS configuration
```

## Cost of HIPAA Compliance

**Estimated Implementation Costs:**
- Developer time: 2-4 weeks
- Security audit: $5,000 - $20,000
- Penetration testing: $3,000 - $15,000
- Annual compliance: $2,000 - $10,000
- Training: $500 - $2,000/year
- Tools & services: $1,000 - $5,000/year

**Violation Penalties:**
- Tier 1: $100 - $50,000 per violation
- Tier 2: $1,000 - $50,000 per violation
- Tier 3: $10,000 - $50,000 per violation
- Tier 4: $50,000 per violation
- Criminal penalties: Up to $250,000 and 10 years imprisonment

## Resources

### Official HIPAA Resources
- [HHS HIPAA Portal](https://www.hhs.gov/hipaa/index.html)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
- [HIPAA Privacy Rule](https://www.hhs.gov/hipaa/for-professionals/privacy/index.html)

### Technical Guides
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)

### Compliance Tools
- [Nightfall AI](https://nightfall.ai) - PHI detection
- [GitGuardian](https://gitguardian.com) - Secrets detection
- [Vanta](https://vanta.com) - Compliance automation
- [Drata](https://drata.com) - Compliance automation

## Support

For HIPAA compliance questions:
1. Consult with legal counsel
2. Hire a HIPAA compliance consultant
3. Contact your organization's security officer
4. Review HHS HIPAA guidance

**Disclaimer:** This document provides general guidance only and does not constitute legal advice. Consult with qualified legal and compliance professionals for your specific situation.
