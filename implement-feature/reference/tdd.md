# TDD Practices (reference)

Companion to `implement-feature`. Read this before writing code yourself — in Lightweight Mode, or in full mode when slices are built inline rather than delegated. An orchestrator that delegates every slice does not need it: the subagent's briefing carries the rules.

## TDD Philosophy
 
### Core Principle: Test Behaviour, Not Implementation
 
Tests should verify behaviour through public interfaces, not implementation. Code can change entirely; tests shouldn't.
 
**Good tests** are integration-style: they exercise real code paths through public APIs. They describe WHAT the system does, not HOW. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.
 
**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (e.g. querying a database directly instead of using the interface). The warning sign: your test breaks when you refactor, but the behaviour hasn't changed.
 
### Characteristics of Good Tests
 
- Tests observable behaviour (what callers actually care about)
- Uses public API only
- Survives internal refactors without breaking
- Describes WHAT, not HOW
- One logical assertion per test
- Reads like a specification
### Characteristics of Bad Tests
 
- Mocks internal collaborators
- Tests private methods
- Asserts on call counts or call order
- Breaks when refactoring without behaviour change
- Test name describes HOW, not WHAT
- Verifies through external means instead of the interface
Worked examples of each — good vs bad, and verifying through the interface rather than bypassing it — are in `reference/design-practices.md`. Read it when a test's shape is genuinely unclear, not as a matter of course.
 
### Anti-Pattern: Horizontal Slices
 
Do not write all tests first and then all implementation. That is "horizontal slicing" — treating RED as "write all the tests" and GREEN as "write all the code."
 
This produces bad tests:
 
- Tests written in bulk test *imagined* behaviour, not *actual* behaviour
- You end up testing the *shape* of things (data structures, function signatures) rather than user-facing behaviour
- Tests become insensitive to real changes — they pass when behaviour breaks, fail when behaviour is fine
- You outrun your headlights, committing to test structure before you understand the implementation
Correct approach: vertical slices via tracer bullets. One test → one piece of implementation → repeat. Each test responds to what you learned from the previous cycle.
 
```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5
 
RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```
 
## When to Mock
 
Mock at **system boundaries** only.
 
**Do mock:**
 
- External APIs (payment, email, third-party services)
- Databases (sometimes — prefer a test DB)
- Time and randomness
- File system (sometimes)
**Don't mock:**
 
- Your own classes or modules
- Internal collaborators
- Anything you control
If you find yourself mocking your own code to test your own code, the design has a problem — usually a missing seam or a shallow module.
 
`reference/design-practices.md` covers interface design for testability, deep vs shallow modules, and how to design boundaries that are easy to mock. Read it in Step 2 when a slice introduces a new module or a new system boundary — not for a slice that follows an existing pattern.
 
## Refactor Candidates
 
After a TDD cycle, look for:
 
- **Duplication** → extract function/class
- **Long methods** → break into private helpers (keep tests on the public interface)
- **Shallow modules** → combine or deepen
- **Feature envy** → move logic to where the data lives
- **Primitive obsession** → introduce value objects
- **Existing code** that the new code reveals as problematic
## Test File Organisation

Place test files in `__tests__` subdirectories co-located with their source module, not in a top-level `tests/` directory:

```
✓ src/mcps/google-docs-mcp/__tests__/
  - config.unit.test.ts
  - install.unit.test.ts

✓ src/prerequisites/1password/__tests__/
  - check.unit.test.ts
  - install.unit.test.ts

✓ src/__tests__/
  - integration.integration.test.ts   ← spans multiple modules

✗ tests/
  - config.test.ts   (wrong — not co-located, no type suffix)
```

**File naming:**
- Unit tests: `.unit.test.ts` (TypeScript) / `.unit.test.js` (JavaScript) — tests a single module in isolation, all external dependencies mocked
- Integration tests: `.integration.test.ts` / `.integration.test.js` — tests how multiple modules compose, or tests against built output / real external processes
- Match the source language of the project — `.ts` for TypeScript projects, `.js` for JavaScript-only projects

**What goes where:**
- Single-module tests with mocked deps → `__tests__/` inside that module's directory
- Multi-module composition tests → `src/__tests__/` (or the closest shared parent)
- Post-build smoke tests (import from `dist/`) → project-root `tests/` directory (they can't be co-located with source)

**Vitest config:** Projects should run unit and integration tests separately (`test:unit`, `test:integration`) and together (`test`) via named vitest projects or include patterns. The combined `test` script is what CI uses.

If a project has chosen a different convention, surface the inconsistency rather than silently picking sides.

## Checklist Per Cycle
 
```
[ ] Test describes behaviour, not implementation
[ ] Test uses public interface only
[ ] Test would survive an internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
[ ] Tests pass
[ ] Coverage is adequate
[ ] Type-check passes (if TypeScript project)
[ ] Lint passes on touched files (if the project has a linter) — end of change, not every cycle
```

## Verifying Interactive CLIs

Arrow-key/`select`-style prompts cannot be driven by piping text to stdin — they need a raw TTY and will exit with an error when it closes. Don't retry pipe variations hoping one works: verify the CLI *reaches* the prompt correctly, and cover the branching logic behind it with unit tests using injected callbacks.

## What to Avoid
 
- Writing all tests upfront (horizontal slicing)
- Anticipating future tests
- Mocking internal functions or private methods
- Adding speculative features
- Refactoring while tests are RED
- Testing implementation details instead of behaviour
- Refactoring before reaching GREEN
- Reading whole files and re-reading files to find one function (see **Working Efficiently**)
