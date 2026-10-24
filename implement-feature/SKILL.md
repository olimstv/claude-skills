---
name: implement-feature
description: Implement code changes using vertical-slice test-driven development. Full mode works from `.scratch/feature-name/` docs (README, DECISIONS, slices) produced by the `plan-feature` skill; Lightweight Mode applies the same TDD, testing, and verification practices to bug fixes, small refactors, and other changes too small to warrant planning docs. DO NOT invoke this skill on your own judgement of a user's request. It is reached exactly two ways: the user runs `/implement-feature` explicitly, or the `plan-feature` skill routes here. For any unprompted coding request — a new feature, a bug fix, a refactor — invoke `plan-feature`; it decides whether the work needs planning and routes here when it doesn't.
---
 
# Implement Feature
 
Implement code changes using vertical-slice TDD. Small changes run in Lightweight Mode, below. Planned features run in full mode, from `.scratch/` planning docs, to a review cadence the user chooses up front.

This file holds what every mode needs. Mode-specific detail lives in `reference/`, read only when that mode or situation applies. Read these with the Read tool, not `cat` — keep context lean by opening each only at the moment its row applies:

| File | Read when |
| --- | --- |
| `~/.claude/commands/implement-feature/reference/full-mode.md` | Planning docs exist — read it before anything else |
| `~/.claude/commands/implement-feature/reference/tdd.md` | You are about to write code yourself — Lightweight Mode, or full mode building slices inline |
| `~/.claude/commands/implement-feature/reference/delegation.md` | Full mode has chosen to delegate slices to subagents |
| `~/.claude/commands/implement-feature/reference/inline-slice.md` | Full mode is building slices inline, not delegating |
| `~/.claude/commands/implement-feature/reference/finish.md` | Full mode: every slice is `done` |
| `~/.claude/commands/implement-feature/reference/repo-memory.md` | You are about to write or update a `docs/memory/` entry |
| `~/.claude/commands/implement-feature/reference/design-practices.md` | A change introduces a new module or system boundary, or a test's shape is unclear |
 
## How this skill is invoked

**Never auto-invoke this skill.** Do not reach for it because a request sounds like coding work. There are exactly two legitimate entry points:

1. **The user runs `/implement-feature`** — with or without a `.scratch/feature-name/` path.
2. **`plan-feature` routes here** — either after planning a feature, or because it judged the task too small to need planning.

If you are about to invoke this skill for any other reason, invoke `plan-feature` instead and let it route. That skill owns the plan-or-just-build decision; making that call here duplicates it and gets it wrong more often, because the requirements haven't been grilled yet.

Once invoked, pick the mode:

- **Planning docs exist** at `.scratch/feature-name/` → full mode. Read `reference/full-mode.md` now and follow it.
- **Feature-sized work, no planning docs** → say so and suggest `plan-feature`, or ask the user to point you at the docs if they live elsewhere.
- **Small work** (bug fix, small refactor, one-off script, minor tweak) → **Lightweight Mode** (below). This is where `plan-feature` routes tasks too small for full planning.

## Lightweight Mode (small changes, no planning docs)

For bug fixes, small refactors, and other changes too small for `.scratch/` scaffolding. Skip the planning docs and per-slice checkpoints, but keep every engineering practice. The workflow:

1. **Preview & confirm.** State in 2–5 sentences: the problem, the intended change, the files affected, and how you'll verify it. For trivial or clearly-scoped changes proceed directly; if scope or approach is ambiguous, ask before coding.
2. **Read before writing.** Read the code you're changing and its existing tests — the parts you need, per **Working Efficiently** below. Check `package.json` scripts for the correct test command (never assume `npm test` works bare). If touching custom hooks/wrappers, read their source first.
3. **TDD the change.** Read `reference/tdd.md` first. Write ONE failing test that reproduces the bug or specifies the new behaviour (RED), then the minimal code to pass (GREEN). Follow all conventions in this skill: test behaviour not implementation, mock only at system boundaries, realistic fixtures, `.unit.test.*` / `.integration.test.*` naming, co-located `__tests__/` directories. Exception: pure refactors with existing coverage — run the existing tests before and after instead of writing new ones.
4. **Refactor only after GREEN**, running tests after each step.
5. **Verify.** Run the full relevant test suite, type-check if it's a TypeScript project, and lint the touched files if the project has a linter (see **Linting**). For user-facing changes, verify in the running app, not just via tests. Report actual results — including failures.
6. **Report.** Summarise what changed, what was tested, and anything surprising found along the way. Then run `bash ~/.claude/commands/implement-feature/context-usage.sh`; if it exits 1, end the report with one line suggesting `/clear` before the next task.

If the same fix fails verification twice, stop and report what you tried and what each attempt showed. A third variation of a failing approach rarely works and costs the most.

**Working Efficiently** and **Linting** below, and everything in `reference/tdd.md`, apply in Lightweight Mode exactly as in full mode. The only things dropped are the planning docs and the per-slice approval loop.

## Working Efficiently

Every tool result stays in context and is re-sent on every later turn. Finding and reading code is most of what implementation costs — far more than writing it. So:

- **Search narrowly.** Start with `grep -rln` (file names only) or `grep -rn … | head -30`. Exclude `node_modules`, `dist`, `build`, `vendor`, `.next`, coverage output, and lockfiles. Search for a symbol name, not a common word.
- **Read the part you need.** For a file over ~300 lines, find the line with `grep -n`, then Read with `offset`/`limit` around it. Read a whole file only when you need its whole structure.
- **Read once.** Do not re-open a file already read in this context unless it has changed since. Do not read a file back to check an edit — the Edit tool fails loudly when it does not apply.
- **Edit with the Edit tool, not Python or `sed -i`.** A Python `str.replace` that matches nothing changes nothing and still reports success, so the file then has to be read back to find out. Keep scripted edits for one mechanical change across many files, and confirm them with `git diff --stat`, not by reading the files.
- **Run the narrowest test while iterating.** One test file, or a name filter, during RED/GREEN. The full suite runs at verification.

## Linting

Code that passes its tests but fails the project's lint step is not done — CI will reject it. If the project has a linter or formatter, every change must pass it before it is reported as finished.

- **Detect it once**, alongside the test command. Signs: `biome.json` / `biome.jsonc`, an ESLint or Prettier config, `phpcs.xml`, `ruff` or `flake8` config, or a `lint` / `check` / `format` script in `package.json`. Prefer the project's own script, so its config and plugins apply.
- **Lint at the end of the change, after Refactor** — not every RED/GREEN cycle.
- **Lint only the files you touched** — `git diff --name-only` plus `git ls-files --others --exclude-standard`. For example `npx biome check <files>` or `npx eslint <files>`. It is faster, and the output carries only your problems.
- **Auto-fix first, then fix the rest by hand** — `biome check --write <files>`, `eslint --fix <files>`. Re-run the tests afterwards: a fixer changes code. Never run a fixer over the whole repo; it buries your change in unrelated diffs.
- **Learn from the first failure.** When the linter flags a pattern, write the rest of the change to match rather than fixing the same rule again later.
- **Pre-existing errors** in code you did not touch: leave them, and report them. Never add a suppression comment (`biome-ignore`, `eslint-disable`) without saying so and why.
- **No linter configured** → say so in one line and move on. Do not add one.
 
## Guard Against Hangs (any command, script, or tool run)

- Run anything that could block with an explicit timeout or in the background; if it goes quiet, kill it and inspect — don't wait indefinitely.
- Scripted mocks/stubs must throw when exhausted — never silently repeat their last response into a loop.
- Before running loop-based code (`for(;;)`, `while(true)`, polling loops), check every exit condition is reachable from the given inputs.
