# Technology Choices: Ruby with Bundler

This document explains why Ruby with Bundler was chosen for the Prescription Event Processor project, why Rails was not included, and why Ruby was selected over other programming languages.

## Why Ruby?

### Extensibility

Ruby's dynamic nature and flexible syntax make it highly extensible:

- **Metaprogramming capabilities**: Ruby's metaprogramming features allow for elegant abstractions and DSLs (Domain-Specific Languages)
- **Open classes**: Ability to extend existing classes without inheritance, enabling clean, readable code
- **Duck typing**: Focus on behavior rather than type, allowing for flexible interfaces and easier testing
- **Mixins and modules**: Enable code reuse and composition without complex inheritance hierarchies

**Example from this project**: The clean, readable syntax makes the business logic easy to understand:
```ruby
patient.total_fills  # Clear, expressive method names
prescription.income   # Self-documenting code
```

### Built-in Features

Ruby comes with a rich standard library that reduces external dependencies:

- **String manipulation**: Excellent support for text processing (regex, string methods)
- **File I/O**: Simple, intuitive file handling (`File.open`, `IO` methods)
- **Collections**: Powerful array and hash operations (`map`, `select`, `sum`, `any?`)
- **Enumerable module**: Provides powerful iteration methods out of the box
- **Exception handling**: Robust error handling with `rescue`, `ensure`, `raise`
- **Command-line argument parsing**: Built-in `ARGV` support

**Example from this project**: Processing input lines is straightforward:
```ruby
parts = stripped_line.split(/\s+/)  # Simple string parsing
@prescriptions.values.sum(&:net_fills)  # Elegant aggregation
```

### Leveraging Gems

Ruby's gem ecosystem provides powerful, well-maintained libraries:

- **RSpec**: Industry-standard testing framework with excellent matchers and DSL
- **FactoryBot**: Flexible test data generation with traits and callbacks
- **Faker**: Realistic random data generation for testing
- **RuboCop**: Comprehensive code style and quality enforcement
- **Bundler**: Reliable dependency management with version locking

**Benefits**:
- **Rapid development**: Gems provide battle-tested solutions for common problems
- **Community support**: Large, active community with extensive documentation
- **Quality assurance**: Popular gems are well-tested and maintained
- **Consistency**: Standard tools ensure consistent code quality across projects

**Example from this project**: FactoryBot enables clean test setup:
```ruby
build(:prescription, :with_fills, fill_count: 3)  # Expressive test data
```

### Multi-OS Support

Ruby runs consistently across different operating systems:

- **Cross-platform compatibility**: Works on macOS, Linux, and Windows
- **Consistent behavior**: Same code runs identically across platforms
- **Version management**: Tools like `rbenv` and `rvm` provide consistent Ruby versions
- **Package management**: Bundler ensures consistent gem versions across environments

**Benefits**:
- **Developer flexibility**: Team members can use their preferred OS
- **Deployment options**: Can deploy to various server environments
- **CI/CD compatibility**: Works seamlessly with most CI/CD platforms
- **Docker support**: Excellent Docker image support for containerization

## Why Not Rails?

Rails is a full-stack web framework, but this project is a command-line utility:

### Project Requirements

- **No web interface needed**: The project processes files/stdin and outputs reports
- **No database required**: Data is processed in-memory, no persistence needed
- **No HTTP server**: No need for routing, controllers, or views
- **Minimal dependencies**: Rails would add unnecessary overhead

### Rails Overhead

Rails includes many components not needed for this project:

- **ActiveRecord**: Database ORM (not needed - no database)
- **ActionController**: Web request handling (not needed - CLI only)
- **ActionView**: Template rendering (not needed - simple text output)
- **Asset pipeline**: CSS/JS compilation (not needed - no web UI)
- **Routing**: URL routing (not needed - command-line arguments)

### Rails Would Add Complexity

- **Configuration overhead**: Rails requires significant configuration
- **Boot time**: Rails has slower startup time than plain Ruby
- **Memory footprint**: Rails uses more memory than necessary
- **Learning curve**: Team members need to understand Rails conventions

### When Rails Would Make Sense

Rails would be appropriate if we were building:
- A web application with a user interface
- An API server
- A system requiring database persistence
- A multi-user application with authentication

## Why Not Other Languages?

### Python

**Advantages**:
- Excellent for data science and scientific computing
- Strong standard library
- Good for scripting

**Why Ruby instead**:
- Ruby's syntax is more expressive for domain modeling
- Better object-oriented design (everything is an object)
- More elegant metaprogramming capabilities
- RSpec is more powerful than Python's unittest/pytest for BDD-style testing

### Go

**Advantages**:
- Excellent performance
- Strong concurrency support
- Single binary deployment

**Why Ruby instead**:
- Go is more verbose for business logic
- Less expressive for domain modeling
- Testing frameworks less mature than RSpec
- Overkill for a simple CLI utility

### Node.js/JavaScript

**Advantages**:
- Large ecosystem
- Good for async operations
- Popular for web development

**Why Ruby instead**:
- Ruby's syntax is cleaner for domain logic
- Better object-oriented design
- More mature testing ecosystem (RSpec vs Jest/Mocha)
- Better for command-line tools (Ruby was designed for scripting)

### Java

**Advantages**:
- Strong typing
- Excellent tooling
- Enterprise support

**Why Ruby instead**:
- Much more verbose (boilerplate code)
- Slower development velocity
- Overkill for a simple CLI utility
- Less expressive for domain modeling

## Why Bundler?

Bundler provides essential dependency management:

### Dependency Resolution

- **Version locking**: `Gemfile.lock` ensures consistent versions across environments
- **Conflict resolution**: Automatically resolves gem version conflicts
- **Reproducible builds**: Same versions installed every time

### Development Workflow

- **Isolated environments**: `bundle install` creates isolated gem environments
- **Version management**: Easy to specify Ruby and gem versions
- **CI/CD integration**: Works seamlessly with continuous integration

### Project Benefits

- **Consistency**: All developers use the same gem versions
- **Reliability**: Prevents "works on my machine" issues
- **Security**: Easy to update gems for security patches
- **Documentation**: `Gemfile` serves as dependency documentation

## Summary

Ruby with Bundler was chosen because:

1. **Extensibility**: Ruby's flexible syntax enables clean, maintainable code
2. **Built-ins**: Rich standard library reduces dependencies
3. **Gems**: Powerful ecosystem provides battle-tested solutions
4. **Multi-OS support**: Consistent behavior across platforms
5. **Right-sized**: Plain Ruby is perfect for CLI utilities - Rails would be overkill
6. **Developer experience**: Excellent tooling and testing frameworks

This combination provides the perfect balance of power, simplicity, and maintainability for a command-line prescription event processor.

