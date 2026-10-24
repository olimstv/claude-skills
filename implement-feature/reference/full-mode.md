# Full Mode (reference)

Companion to `implement-feature`. Read this when `.scratch/feature-name/` planning docs exist. The engineering practices in `SKILL.md` (working efficiently, linting) and `tdd.md` still apply to every slice — whoever builds it.

## Quick Start

1. Ask the user which feature to implement (or pick the only one in `.scratch/` if there's one).
2. Load `README.md`, the slice index, linked ADRs, the `CONTEXT.md` term list, and the `PROGRESS.md` header (Phase 1). Leave `DECISIONS.md` and the rest of `PROGRESS.md` unread until something forces them open.
3. **Ask where they want to review and — when delegating with the experimental agent installed — which subagent to use** (Phase 1.5, one call). Do not ask permission to begin.
4. Decide whether to delegate the slices to subagents (Phase 1.6) — delegation is the default for 3+ slices. Your call, not the user's.
5. **FOR EACH SLICE IN SEQUENCE:**
   - Preview the slice (what to build, acceptance criteria, affected files)
   - Implement using TDD
   - Mark `Status: in-progress` before building, `Status: done` after it verifies
   - Run `context-usage.sh` and include the figure in the slice's done line; past 200k, add the `/clear` note to it — never stop for it
   - If this slice is a review point: show results and the context size, ask "Looks good?", then re-ask the cadence question
   - Otherwise: say it's done and start the next slice immediately
6. After all slices: read `finish.md` — end-to-end verification, then the retrospective.

**CRITICAL:** The review cadence is the user's to set, not yours to assume — ask in Phase 1.5, re-ask at every review point you reach, and honour each answer exactly in between. Never insert approval gates they didn't ask for, and never skip one they did. The context size is reported, never a reason to stop.

## Workflow
 
### Phase 1: Load Context
 
Load the feature-level picture and nothing more. Slice bodies are read one at a time, later, immediately before the slice is built.

**Read in full:**

- `.scratch/feature-name/README.md` — problem, solution, scope, cross-cutting constraints, feature-level acceptance criteria
- `docs/memory/README.md` — the repo memory index. **The index only.** Open an individual entry when its one-line hook touches something this feature actually does.
- Any ADRs in `docs/adr/` linked from `README.md` § References

**Read as a list only — use the script, do not open the files:**

```bash
bash ~/.claude/commands/implement-feature/slice-index.sh .scratch/feature-name
```

It prints every slice's number, title, `Status`, `Complexity`, `MCP`, and `Blocked by` in one table, names the next slice to work on, and validates the contract. That is everything needed to order the work, run the Phase 1.5 questions, and choose a model and agent. Do not open the slice bodies yet — each one is read in Step 1 of its own slice.

**A non-zero exit means the plan is malformed.** It reports duplicate `in-progress` slices, a `Blocked by` pointing at a slice that does not exist, a `done` slice depending on an unfinished one, a dependency cycle, and bad `Status`/`Complexity` values. Fix these before implementing — every one of them otherwise surfaces halfway through the work, when it is far more expensive.

**Read the domain glossary as a term list only** — `grep -n '^#' docs/CONTEXT.md` (or `CONTEXT.md` at project root). The headings are enough to recognise which terms a slice uses; open an entry with `sed -n` when a slice needs it, and hand subagents the term names plus the file path rather than the definitions.

**Read only the header of `.scratch/feature-name/PROGRESS.md`, if it exists** — everything above the first slice note:

```bash
sed -n '1,/^## Slice/p' .scratch/feature-name/PROGRESS.md
```

The header holds the project mechanics a previous session resolved (see **Progress Notes**). The per-slice handoff notes below it grow with every slice — 6k+ tokens by slice 07 — and this context needs almost none of it: the slice index gives status, subagent briefings point at the file instead of carrying it, and the retrospective greps only the `Surprises` lines. Open an individual note only when the next slice is `Blocked by` that slice and you need its exact interfaces to write a `Where to start` pointer — `grep -A6 '^## Slice 03' …`, not a full read.

**A slice marked `in-progress` means a previous session stopped part-way through it.** Resume it before starting anything still `pending`, and do not trust either that its work is absent or that it is complete:

1. Read that slice's body.
2. Find what actually landed. `git status` and `git diff` against the branch point show uncommitted work fastest; `git log` shows what was committed. Note that `.scratch/` is gitignored, so slice files themselves will not appear — read those directly.
3. **Re-run the tests before believing anything.** A part-built slice routinely has a failing test, a test that was never written, or a test passing against a stub. This is the one place where "it looks finished" is most likely to be wrong.
4. Tell the user what you found and where you are picking up, in two or three lines, before writing any code.

Then continue that slice from the step it stopped at. If what you find contradicts the slice's plan, that is an early-stop trigger — raise it rather than building over it.

Reading ten slice bodies up front fills this context with detail for work you have not started, and most of it is re-read anyway at the moment it is needed. Open a slice's body in Step 1 of that slice.

This skill's scripts (`slice-index.sh`, `check-scratch-refs.sh`, `context-usage.sh`) live at the user level (`~/.claude/commands/implement-feature/`). There is no repo-level copy, so invoke them via `~` — a relative path will not resolve.

**Resolve the project mechanics once:**

If the `PROGRESS.md` header already records them, use those and skip discovery — re-check only if a command fails. Otherwise find the exact commands this project uses, from `package.json` scripts or the equivalent, state them in one line before starting, and write them into the `PROGRESS.md` header (creating the file) so no later session repeats the hunt:

- Test command, including any required flags or env vars (`NODE_OPTIONS`, `--runInBand`, test-group flags)
- Type-check command, if it's a TypeScript project
- Lint command, if the project has a linter or formatter (see **Linting** in `SKILL.md`) — or "none configured"

Never assume a bare `npm test` is correct. Resolving this once removes a per-slice discovery step and gives you the `Project mechanics` block every delegation briefing needs. If a slice later needs a narrower command, derive it from these.

**Do NOT read `DECISIONS.md` yet.** Confirm it exists, then leave it. It holds the *why*, which you don't need to build a slice that's going to plan, and reading it up front spends context on rationale for decisions you may never revisit. Open it — just the relevant entry — when one of these happens:

- The code contradicts what a slice describes
- You're tempted to deviate from the plan
- The user questions why something was specified a certain way
- A slice's approach looks wrong and you're about to raise it

If any file above is missing, surface that — don't proceed with an incomplete picture. A missing `DECISIONS.md` is a red flag: it usually means trade-offs weren't captured, and you'll re-litigate them mid-implementation.
 
### Phase 1.5: Agree the Review Points

Do not ask for permission to begin. Ask where the user wants to stop and review, then implement to that answer.

<a id="the-cadence-question"></a>
**The cadence question.** Use `AskUserQuestion`, single-select, header `Review points`. Build the options from the slices not yet `done` — `pending` and any `in-progress` one — never from those already `done`:

- `After every slice (Recommended)` — stop after each one
- `Only when everything's done` — implement the rest, review once at the end
- One option per **intermediate** remaining slice: `After slice 0K-<name>` — stop there, then continue to the end without further stops

Only intermediate slices get their own option. "After the last slice" is the same stop as "only when everything's done", so never offer it twice.

The tool caps a question at 4 options, which fits up to 3 remaining slices. With more, offer just the two cadence options plus `At slices I name`, and take the specifics from the user's free-text answer.

<a id="the-agent-question"></a>
**The agent question.** Ask it in the **same** `AskUserQuestion` call, as a second question — header `Subagent`, single-select — but only when **all** hold:

- Phase 1.6 will delegate. Make that call now, before asking; it needs only the slice index, and it stays yours, not the user's.
- The experimental agent is installed: `test -f ~/.claude/agents/slice-implementer.md`.
- At least one remaining slice has `MCP: none` in the slice index. A slice that needs MCP servers always goes to the standard agent (`delegation.md` § Picking the agent), so when every remaining slice needs one, there is nothing to choose.

> Which subagent should build the delegated slices?

- `Standard (general-purpose)` — the default subagent with every tool, briefed with the full rules
- `Experimental (slice-implementer)` — a lean subagent limited to file and shell tools, with the rules built in. Starts each slice at a fraction of the context; cannot fetch web docs. Slices that need MCP servers still go to the standard agent

Mark neither as recommended — the user is comparing them. Ask it once, here; do **not** re-ask it at review points. One agent per run keeps the comparison clean — the MCP override is per slice and recorded in each `Built by` line, so it does not muddy it. Follow the answer in `delegation.md` § Picking the agent.

Then follow the cadence answer:

- **After every slice** → stop at Step 6 of each one.
- **Only when everything's done** → run the remaining slices start to finish, then go to Phase 3. Report progress as you go, but do not stop.
- **Specific slices** → stop at Step 6 of the named slices only; pass straight through the others.

Ask the cadence question here, and again at every review point you reach (Step 6) — each time over what's left. A user who wanted a checkpoint early often doesn't want one for the rest, and the reverse is just as common once they've seen the first slice land.

Whatever the answer, three things always happen: each slice is built with the full TDD cycle, the `Status` line is moved to `in-progress` and then `done` as each slice starts and finishes, and Phase 3 end-to-end verification runs at the end.

Ignoring the agreed cadence is a failure in either direction: blowing past a review point the user asked for, or stopping for approval they explicitly said they didn't want.

**Stop early regardless of the chosen cadence** when: a slice's plan contradicts the code you find, a slice fails verification twice, or you're about to deviate from `DECISIONS.md`. Agreeing to review later is not agreement to let a broken plan run to completion.

### Phase 1.6: Decide Whether to Delegate

Delegating slices to subagents keeps this context small and lets cheap slices run on a cheap model. A subagent's working transcript — every file it read, every failing test run, every wrong grep — never enters this context; only its ~15-line handoff note does. That is the single largest lever on what this skill costs to run, and it needs nothing from the user.

**Delegation is the default.** Delegate whenever both hold:

- The feature has **3 or more** slices.
- The `Agent` tool is available in this context.

When it applies, delegate — do not weigh it up again per slice. Slices missing a `Complexity` rating (features planned before that field existed) are not a reason to skip delegation: treat them as `4`, or score them yourself from the rubric in `plan-feature`, and carry on. Older plans rated `low` / `medium` / `high` are still valid; `delegation.md` maps them.

**Implement inline instead only for a stated reason**, and say which reason in the one line below. Legitimate ones:

- Under 3 slices — a short feature pays more in cold-start re-discovery than delegation saves.
- Every slice is trivial (`Complexity` 0–1) — one small file, a couple of tool calls, no hunting. Slice count is a proxy for how much transcript the work generates; when the slices are that thin, three cold starts cost more than the transcript they save. This is a judgement about the slices in front of you, not a way to opt out of delegation in general.
- No `Agent` tool here.
- The slices are so entangled that a briefing would have to carry most of this context anyway.

Say which you chose, in one line, and move on — this is not a question for the user.

If delegating, read `~/.claude/commands/implement-feature/reference/delegation.md` now and follow it for Steps 2–5 of each slice. Everything else in Phase 2 stays here, in this context.

### Phase 2: Slice-by-Slice Implementation

**Workflow per slice: Preview → Implement → Verify → (stop if this is a review point) → Repeat**

Work through `.scratch/feature-name/slices/` in dependency order (respecting each slice's `Blocked by` field). One slice at a time — never start a slice before the previous one is verified, even when their `Blocked by` fields look independent. Concurrent slices corrupt each other's files and their test runs collide.

If Phase 1.6 chose delegation, Steps 2–5 happen inside a subagent; Steps 1 and 6 always stay in this context.

**Step 1: Preview**
 
- Read this slice's body now — this is the first time you open it
- Update the slice file: change `Status: pending` to `Status: in-progress`
- Show the user the slice: what to build, acceptance criteria, affected files
- **Deferred-test check:** If the slice file's `Test approach` says "Covered by slice N" or similar, do NOT silently skip TDD. Flag it explicitly: "This slice defers tests to slice N — should I write tests inline here anyway, or follow the planning doc?" Wait for the user to decide before proceeding — or before dispatching, when delegating.
- This is a heads-up, not a gate — proceed straight to Step 2. The user already chose their review points in Phase 1.5.

**Why this matters:** Skipping this checkpoint means you can spend an hour building the wrong thing because the planning doc was slightly stale, the user changed their mind, or your understanding of the requirement is wrong. This is the only guaranteed checkpoint to catch those problems.
 
**Steps 2–5** — delegated: follow `delegation.md`. Inline: read `~/.claude/commands/implement-feature/reference/inline-slice.md` (and `tdd.md`) once, before the first inline slice.

**Step 6: Verify & Mark Complete**
 
- **Run the tests, the type-check, and the lint yourself.** If a subagent implemented the slice, its report that they pass is a claim, not evidence — re-run all three in this context before believing it. This is cheap and it is the whole safety net on delegated work.
- Show the user the test results and any coverage delta
- If it's a TypeScript project, run type-check and confirm no errors
- If the project has a linter, lint the files this slice touched and confirm no errors
- If verification fails, send it back — re-dispatch the subagent with the failure output, or return to Step 3 inline — this is not a review point, it's a defect
- Update the slice file: change `Status: in-progress` to `Status: done`

- Append this slice's handoff note to `.scratch/feature-name/PROGRESS.md` (see **Progress Notes** below) with `cat >> … <<'EOF'` — append blind; do not read the file first or back afterwards

Exactly one slice may be `in-progress` at a time. If you are about to mark a second one, you have started a slice before finishing the last — stop and finish that one first.

The `Status` line is the contract back to `plan-feature` and to anyone reviewing progress — keep the field exactly as written.

**Then check the context size** — every slice, whatever the cadence, delegating or not. See **Context checkpoint** below.

**Then check the cadence agreed in Phase 1.5:**

- **This slice isn't a review point** → state in one line that it's done and passing, with the context size, then start the next slice immediately. Do not ask. E.g. `Slice 03 done — 24 tests passing, lint clean. Context: 87k.`
- **It is a review point** → show the results and the context size, ask "Looks good?" and wait. If the user asks for changes, send the slice back through Steps 3–5 (delegated or inline) and iterate until they're happy. Then, before starting the next slice, **re-ask the cadence question** over the slices not yet `done` and follow the new answer.

Skip the re-ask only when no slices remain — go straight to Phase 3.

The re-ask is the point of the checkpoint. A review point exists so the user can change direction, and how closely they want to watch the rest is the most common thing they'll want to change once they've seen real code land.

**Context checkpoint (every slice boundary).** A long feature builds up a transcript that is re-sent on every turn. By the middle of a feature most of it is dead weight: failed test runs, files read three slices ago, reasoning now recorded in `PROGRESS.md`. Past roughly 200k tokens it also costs quality — attention thins across a long context, and early-session detail starts to crowd out the current slice. Delegating slows the growth but does not stop it: handoff notes, re-run test output, and slice bodies all accumulate here.

You cannot see your own context size, and guessing from slice counts does not work. Measure it. After the slice is `done` and its `PROGRESS.md` note is written, run:

```bash
bash ~/.claude/commands/implement-feature/context-usage.sh
```

Its `CONTEXT` line gives the figure for the slice's done line and every review stop. Report it every time, so the user can see where things are at without asking. **It never stops the work** — the cadence alone decides the stops. The user is watching the figure and can run `/clear` whenever they choose.

- **Exit 0** — below 200k. Report the figure and carry on.
- **Exit 2** — could not tell. Report `Context: unknown` and carry on.
- **Exit 1, slices remain** — report the figure with the clear note on the end, and carry on:

> Slice 05 done — 31 tests passing, lint clean. Context: 214k — over 200k tokens, use `/clear` to reduce token usage between slices (re-run `/implement-feature .scratch/feature-name` to pick up from PROGRESS.md).

- **Exit 1, no slices remain** — report the figure only; Phase 3 runs in this session.

Suggest `/clear`, not `/compact`: `PROGRESS.md` and the slice `Status` lines already hold the record, and a summary is lossier than either. Add the note only at a slice boundary, never while a slice is `in-progress` — the record must be complete before the context is thrown away.
 
### Phase 3 & 4: Verify and Retrospect

Once every slice is `done`, read `~/.claude/commands/implement-feature/reference/finish.md` and follow it. Keep collecting retrospective candidates as you go (see **Retrospective notes** below) — `finish.md` uses them.

## Retrospective notes

**Collect as you go, not at the end.** Every time one of these happens during Phase 2, note it in one line and carry it forward:

- The user corrected you
- You got something wrong the first time
- You had to be told a convention
- A slice's `Gotchas` turned out to be missing something that bit you
- A delegated slice reported a surprise in its handoff

Reconstructing this from the whole conversation at the end is expensive and misses most of it. `finish.md` turns these into the Phase 4 offer.

## Progress Notes

`.scratch/feature-name/PROGRESS.md` starts with a header holding the project mechanics, written once in Phase 1, then accumulates one short note per completed slice. Append to it in Step 6, every slice, whether you built it yourself or delegated it.

```markdown
# Progress — <feature-name>

## Project mechanics
Test: <exact command and flags>
Type-check: <exact command, or "n/a">
Lint: <exact command, or "none configured">

## Slice 03 — <title>
- Built: <one line>
- Files touched: <paths>
- New exports/interfaces: <signatures the next slice would need>
- Conventions confirmed: <e.g. tests use renderWithProviders from test-utils>
- Surprises: <anything that contradicted the plan, or "none">
- Built by: <inline | general-purpose | general-purpose (mcp: <servers>) | slice-implementer> · <model> · <subagent_tokens from the Agent result, or "n/a" inline> · <verification passed first time | needed N re-runs>
```

The `Built by` line is how the two subagent types get compared across runs. Take the token figure from the `subagent_tokens` field the Agent tool returns, not from an estimate.

When a subagent built the slice, its returned `## Handoff` block is the note — append it as-is under the slice heading. When you built it yourself, write the same five fields. Keep it to those fields; this is a handoff, not a changelog. The commit history already records what changed.

It earns its keep three ways:

- **Resume.** Earlier slices' interfaces, conventions and decisions survive a `/clear` without re-reading their code. Without this file, a resumed session re-derives decisions slices 01–03 already made, and often makes them differently. The header spares it re-discovering the project's commands.
- **Delegation briefings.** Each subagent reads this file itself, so earlier slices reach it without being pasted through this context.
- **The retrospective.** The `Surprises` lines are most of Phase 4's raw material, already collected.

`PROGRESS.md` is ephemeral and dies with `.scratch/feature-name/`. Nothing permanent may reference it — copy anything worth keeping into `docs/memory/`, `CONTEXT.md`, or an ADR during Phase 4.

## Status Tracking
 
As each slice completes:
 
```
pending  →  in-progress  →  done
```

- `pending` — not started. Written by `plan-feature`; never written by this skill.
- `in-progress` — set in **Step 1**, before any code is written. At most one slice holds this at a time.
- `done` — set in **Step 6**, only after tests, type-check, and lint have passed **in this context**.

Open `.scratch/feature-name/slices/0X-*.md` and edit the line in place. Exact spelling, lower-case — downstream tooling parses it literally.

Never skip `in-progress` on the grounds that a slice will be quick. Its whole value is being correct at the moment things stop unexpectedly: a killed session, a crash, a user walking away mid-slice. A slice that reads `pending` while half its code sits on disk is worse than no status at all, because the next session trusts it.

This is the handoff record — anyone reviewing progress, human or agent, reads the slice files rather than the transcript. It is also what lets a fresh context resume the work: see Phase 1.

**Delegated slices:** the subagent never touches the `Status` line. You set `in-progress` before dispatching it and `done` after you have re-run the tests yourself. A slice left `in-progress` after a subagent returns means its work has not been verified here yet.

## Changing the Review Cadence Mid-Run

The cadence is set in Phase 1.5 and re-asked at every review point, but the user can also change it unprompted at any moment:

- **Fewer stops** — "just implement the rest", "no more checkpoints", "stop asking me"
- **More stops** — "check with me after each one from now on", "stop after the next slice"

Apply the change from the next slice onward and confirm it in one line. Take it only from an explicit instruction — never infer a cadence change from tone, from a user approving several slices quickly, or from them saying "looks good" without further comment.
