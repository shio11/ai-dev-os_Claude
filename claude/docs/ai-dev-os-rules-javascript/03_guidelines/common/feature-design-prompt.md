# Feature Design Prompt

A prompt template for making guideline-based design decisions during the design phase of new features.

---

## Prompt

```markdown
Please design the following feature.

## Design Process

### 1. Organizing Requirements
- What problem does this feature solve
- Who is affected and what is the expected outcome

### 2. Architecture Decisions (02_decision-criteria/architecture.md)

#### Data Flow Design
- Loading method (ESM served by Python / classic script in a generated HTML)
- Data sources (Python API / embedded JSON / user input)
- Data flow (app → views → api / lib → types)
- Which logic stays in Python (business rules) and which in JS (display, instant checks)

### 3. File Structure Design

Design the file structure following project-structure.md:
- List files to create or modify
- Assign each file to the correct layer (app / api / types / lib / views)
- Verify views do not import each other

### 4. Security Design (common/security.md)
- [ ] Where untrusted data enters (API response, embedded JSON, form, URL, storage) and its guard function
- [ ] No untrusted data in `innerHTML`
- [ ] No secrets or credentials in JS or HTML
- [ ] Handling of sensitive data shown on screen

### 5. Error Handling Design (02_decision-criteria/error-strategy.md)
- List and classify possible errors (System / Application / User)
- Display method for each error
- Identify retryable errors

### 6. Test Strategy (common/testing.md)
- Unit test targets (pure functions in `lib`, guard functions in `types`)
- E2E test targets (screens driven from pytest)

## Design Checklist

### Required
- [ ] Validation in Python, instant checks only in JS
- [ ] JSDoc types on every function
- [ ] Errors shown on screen with what failed and what to do
- [ ] File and variable names following naming conventions (common/naming.md)

### Recommended
- [ ] Accessibility considerations
- [ ] Performance optimization
- [ ] Edge case testing

### Requires Decision
- [ ] Can existing common patterns be reused (02_decision-criteria/abstraction.md)
- [ ] Is introducing new technology/libraries needed (02_decision-criteria/technology-selection.md)

## Output Format

### Design Document

#### Overview
{Explain the purpose of the feature in 1-2 sentences}

#### File Structure
{List of files to create or modify}

#### Data Flow
{Flow from user action → views → api → Python}

#### Security
{Untrusted inputs and how they are validated and rendered}

#### Error Handling
{Possible errors and how to handle them}

#### Test Plan
{Test targets and types}

#### Open Items
{Points that cannot be decided at the design stage}
```
