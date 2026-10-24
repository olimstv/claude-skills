# Standard-Agent Briefing Blocks (reference)

Companion to `delegation.md`. Read this only when the user chose the **standard** (`general-purpose`) agent. The `slice-implementer` agent has all of this built in — never send it these blocks.

Wrap the core briefing from `delegation.md` with these, copied as written: the first two blocks go immediately after the opening line, the rest go after `## Project mechanics`.

```
## How to work
- TDD in vertical steps: write ONE failing test for the next behaviour, run it
  (RED), write the minimal code to pass (GREEN). Repeat until every acceptance
  criterion is met. Never write a batch of tests up front.
- Refactor only once all tests pass, re-running tests after each step.
- Test behaviour through public interfaces, not implementation details.
- Mock only at system boundaries (external APIs, time, randomness). Never mock
  this project's own modules.
- Fixtures must match the real input format, quirks included (encoding,
  nesting, optional fields the code branches on).
- Name and place test files like the existing tests nearby. If none exist:
  co-located `__tests__/`, suffixed `.unit.test.*` or `.integration.test.*`.
- No speculative features. No code for behaviours the slice does not ask for.
- Run anything that could hang with a timeout.
- If the same approach fails twice, stop and report what each attempt showed.

## Working efficiently
- Search narrowly: `grep -rln` or `grep -rn … | head -30`, excluding
  node_modules, dist, build, vendor, coverage, and lockfiles.
- For files over ~300 lines, find the line with `grep -n`, then Read with
  offset/limit. Read whole files only when you need their whole structure.
- Never re-read a file you have already read unless it changed. Never read a
  file back to check an edit.
- Edit code with the Edit tool, not Python or `sed -i`. Use a script only for
  one mechanical change across many files, then check it with
  `git diff --stat`.
- While iterating, run only this slice's test file. Run the full suite once at
  the end.

<core briefing from delegation.md: ## The slice … ## Project mechanics>

## Before you hand off
If a lint command is given above: once all tests pass, lint only the files you
touched. Auto-fix first (e.g. `--write` / `--fix` on those files only, never
the whole repo), fix the rest by hand, then re-run the tests. Leave
pre-existing errors in code you did not touch, and list them under Surprises.
Never add a lint-suppression comment without saying so in your handoff.

## Rules
- Do not touch files outside this slice's "Files to create/modify" list without
  saying so in your handoff.
- Do not edit the slice file. The orchestrator owns the Status line.
- Do not run `git add`, `git commit`, `git push`, or any other git write
  command. Leave changes uncommitted in the working tree — committing is the
  orchestrator's/user's call, never the subagent's.
- If something needs a human decision, stop and report it. You cannot ask.
- End your reply with the ## Handoff block below and nothing after it.

## Handoff
- Built: <one line>
- Files touched: <paths>
- New exports/interfaces: <signatures the next slice would need>
- Conventions confirmed: <e.g. tests use renderWithProviders from test-utils>
- Surprises: <anything that contradicted the plan, or "none">
```
