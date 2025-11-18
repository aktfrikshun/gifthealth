# SOLID Principles in Prescription Event Processor

This document explains how SOLID principles are applied in the Prescription Event Processor codebase.

## Overview

SOLID is an acronym for five object-oriented design principles that help create maintainable, flexible, and testable software:

- **S**ingle Responsibility Principle
- **O**pen/Closed Principle
- **L**iskov Substitution Principle
- **I**nterface Segregation Principle
- **D**ependency Inversion Principle

## 1. Single Responsibility Principle (SRP)

**Principle**: A class should have only one reason to change.

**Application in this project**:

Each class has a single, well-defined responsibility:

- **`Prescription`** (`app/models/prescription.rb`): Manages a single prescription's state and income calculation
  - Tracks prescription lifecycle (`created`, `fill_count`, `return_count`)
  - Calculates prescription-level income
  - Validates prescription data

- **`Patient`** (`app/models/patient.rb`): Aggregates prescriptions and calculates patient-level statistics
  - Manages collection of prescriptions for a patient
  - Calculates aggregate totals (fills, income)
  - Validates patient data and relationships

- **`PrescriptionEventProcessor`** (`app/services/prescription_event_processor.rb`): Orchestrates event processing and report generation
  - Processes prescription events
  - Generates reports from processed data
  - Manages patient collection

- **`CLI`** (`app/handlers/cli.rb`): Handles command-line input/output
  - Determines input source (file or stdin)
  - Coordinates processing and output
  - Handles I/O errors

## 2. Open/Closed Principle (OCP)

**Principle**: Software entities should be open for extension but closed for modification.

**Application in this project**:

The design allows for extension without modifying existing code:

- **New event types**: Can be added by extending the `case` statement in `process_event` without changing existing event handling logic
- **New output formats**: Can be added by creating new formatter methods or classes without modifying `PrescriptionEventProcessor`
- **New input sources**: Can be added by creating new handler classes (e.g., `APIHandler`, `SQSHandler`) without modifying the service layer
- **New report types**: Can be added by extending `generate_report` or creating new report generators

Example: To add a new event type like `cancelled`, you would:
1. Add a new `when 'cancelled'` clause in `process_event`
2. Add the corresponding method to `Prescription` if needed
3. No need to modify existing event handling code

## 3. Liskov Substitution Principle (LSP)

**Principle**: Objects of a superclass should be replaceable with objects of its subclasses without breaking the application.

**Application in this project**:

While this project doesn't use inheritance hierarchies, LSP is demonstrated through consistent interfaces:

- **`Prescription` instances**: Any `Prescription` instance can be used interchangeably - they all implement the same interface (`fill`, `return_fill`, `income`, `net_fills`, etc.)
- **`Patient` instances**: Any `Patient` instance can be used interchangeably - they all implement the same interface (`get_or_create_prescription`, `total_fills`, `total_income`, etc.)
- **Consistent interfaces**: Models maintain consistent method signatures and behaviors, ensuring they can be swapped without breaking dependents

This principle ensures that if we were to create subclasses (e.g., `SpecialPrescription` extends `Prescription`), they would be fully substitutable.

## 4. Interface Segregation Principle (ISP)

**Principle**: Clients should not be forced to depend on methods they do not use.

**Application in this project**:

Classes expose focused, cohesive interfaces:

- **`PrescriptionEventProcessor`**: Only uses the methods it needs from `Patient` and `Prescription`
  - Uses: `get_or_create_prescription`, `mark_created`, `fill`, `return_fill`, `total_fills`, `total_income`, `has_created_prescriptions?`
  - Doesn't need: `add_prescription`, `prescription_count` (used only in tests)

- **`CLI`**: Depends only on `PrescriptionEventProcessor`'s public interface
  - Uses: `process_line`, `generate_report`
  - Doesn't need: `process_event`, `get_or_create_patient`, `format_report_line` (private methods)

- **Focused model interfaces**: Models expose only what's needed, avoiding bloated APIs
  - `Prescription` doesn't expose internal state like `@fill_count` directly
  - `Patient` doesn't expose internal `@prescriptions` hash directly

## 5. Dependency Inversion Principle (DIP)

**Principle**: High-level modules should not depend on low-level modules. Both should depend on abstractions.

**Application in this project**:

The architecture follows dependency inversion:

- **`PrescriptionEventProcessor`**: Depends on `Patient` and `Prescription` abstractions (their interfaces), not concrete implementations
  - Could swap implementations as long as they implement the same interface
  - Doesn't depend on how `Patient` or `Prescription` are implemented internally

- **`CLI`**: Depends on `PrescriptionEventProcessor` abstraction
  - Could swap `PrescriptionEventProcessor` with a different implementation
  - Doesn't depend on internal details of the processor

- **Layered architecture**: High-level handlers depend on services, which depend on models
  - Each layer depends on abstractions from the layer below
  - Changes to lower layers don't necessarily require changes to higher layers

- **Future extensibility**: This design makes it easy to:
  - Add dependency injection
  - Mock dependencies in tests
  - Swap implementations (e.g., database-backed models vs. in-memory models)

## Benefits of SOLID Principles in This Project

1. **Maintainability**: Each class has a clear purpose, making it easier to understand and modify
2. **Testability**: Small, focused classes are easier to test in isolation
3. **Extensibility**: New features can be added without modifying existing code
4. **Flexibility**: Components can be swapped or extended without breaking the system
5. **Readability**: Clear separation of concerns makes the codebase easier to navigate

## References

- [SOLID Principles (Wikipedia)](https://en.wikipedia.org/wiki/SOLID)
- [SOLID Principles Explained (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2020/10/18/Solid-Relevance.html)

