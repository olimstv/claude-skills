# Slice Delegation (reference)

Companion to `implement-feature` full mode. How to run Steps 2–5 of a slice in a subagent, once Phase 1.6 has chosen to delegate.

### What stays here, what goes out

| Stays in this context | Goes to the subagent |
| --- | --- |
| Step 1 preview to the user | Step 2 plan the interfaces |
| Step 6 test run + type-check + lint | Step 3 tracer bullet |
| Every `Status` line write | Step 4 incremental loop |
| Every question to the user | Step 5 refactor |
| Phase 3 end-to-end verification | |

**A subagent cannot ask the user anything.** The cadence question, "Looks good?", and the deferred-test check all stay here. If a subagent hits something that needs a human decision, it must stop and report rather than guess — say so in its briefing.

### Picking the agent

Follow the user's answer to the agent question in Phase 1.5. If it was not asked — the experimental agent is not installed, or every remaining slice needs MCP servers — use the standard agent.

**MCP override, per slice.** `slice-implementer` is limited to file and shell tools, so it cannot call MCP servers — and the Agent tool has no way to hand a subagent extra tools at dispatch time. So read the slice's `MCP:` line (Step 1 has the body open anyway):

- `MCP: none` → the agent the user chose.
- `MCP: <servers>` → the standard agent with its full briefing, whatever the user chose. Add a `## MCP servers` section to the briefing naming the servers and what the slice uses each for, so it does not hunt for them.
- **No `MCP:` line** (planned before the field existed) → decide from the body: if `What to build`, `Test approach` or `Gotchas` has the implementer calling an MCP server — fetching a Figma frame, reading a ClickUp card, querying a live service through its connector — treat it as needing one. Writing code that *is* or *wraps* an MCP server does not count; only calling one while building does.

Say so in the Step 1 preview when a slice is overridden, in one line: `Slice 04 needs the figma MCP — building it with the standard agent.`

**If `slice-implementer` stops for want of a tool** — its handoff reports it needed an MCP server or web access it does not have — re-dispatch that slice once to the standard agent with the full briefing plus the `## MCP servers` section, and keep the rest of the run on the user's choice. This is not a verification failure; it does not count toward the two-strikes rule.

| Answer | `subagent_type` | Briefing |
| --- | --- | --- |
| Standard | `"general-purpose"` | The core briefing below, wrapped in the blocks from `~/.claude/commands/implement-feature/reference/briefing-standard.md` — read that file once, only for this answer |
| Experimental | `"slice-implementer"` | The core briefing below and nothing more. The agent has the working rules, lint step, rules and `Handoff` format built in; sending them again wastes the saving. |

If the Agent tool rejects `slice-implementer` as an unknown type — the file was installed after this session started — tell the user in one line, switch to the standard agent with the full briefing for the rest of the run, and record it in the `Built by` line. Do not retry.

Record an MCP override in the `Built by` line as `general-purpose (mcp: <servers>)`, so the agent comparison can leave those slices out.

Everything else is identical for both: the model and effort tier below, re-running verification yourself, and the handoff checks.

### Picking the model

Read the slice's `Complexity` score (0–8, the sum of four 0–2 scores — the rubric is in `plan-feature`) and pick the tier:

| Score | Tier | `model` | `effort` |
| --- | --- | --- | --- |
| 0–1 | trivial | `"haiku"` | omit |
| 2–3 | light | `"sonnet"` | `"low"` |
| 4–5 | standard | `"sonnet"` | omit |
| 6–7 | hard | omit — inherits this session's model | omit |
| 8 | hardest | omit | `"high"` |

**Floor:** a `2` for `design` or `hazards` means the **hard** tier at least, whatever the total. A small slice with a shadowed wrapper or an ordering hazard needs judgement, not volume.

**Legacy ratings:** `low` → trivial, `medium` → standard, `high` → hard. A missing rating → standard.

Setting `effort` here is deliberate: this skill is the instruction that authorises it. Pass exactly what the table says.

Move a slice up a tier without hesitation when its `Gotchas` describe something subtle, or when a previous slice's handoff reported surprises in the same area. Never move one down.

If a slice comes back failing verification twice, re-run it one tier up before debugging it yourself. A slice that fails at the top tier is a plan problem, not a model problem — stop and surface it, per the early-stop rules in Phase 1.5.

### The briefing

The saving comes from sparing the subagent the *hunt* — the greps, the globs, the three wrong files opened before the right one. So pass **pointers, not contents**. A path plus one line of why is worth more than the file pasted in, and costs a fraction.

Good `Where to start` pointers come from the README, the handoff notes returned earlier in this session, and any `docs/memory/` entry you opened in Phase 1 — a memory entry is often exactly the pointer a cold subagent would otherwise spend a dozen greps rediscovering.

Make pointers as precise as you can from what you hold: a file plus the symbol or line beats a file alone, and a file beats a directory. The `New exports/interfaces` lines of earlier handoffs usually give you the symbol names; after a resume, `grep -A6 '^## Slice NN'` the `Blocked by` slices' notes rather than reading `PROGRESS.md` whole.

Build the briefing only from what you already hold. If writing it would mean opening files you haven't read yet, you have moved the cost into this context rather than saving it — leave the pointer out and let the subagent find it. Do not paste `CLAUDE.md`; subagents load project instructions automatically.

Never tell a subagent to follow or load this skill: loading it costs every slice thousands of tokens on rules it does not need. Point it at files it should read for itself — `PROGRESS.md`, `CONTEXT.md` — rather than pasting them: the subagent's context is thrown away after the slice, this one is re-sent on every turn.

The core briefing, for either agent:

```
You are implementing one slice of a planned feature. Everything you need is in
this briefing or the files it points to. Do not load the implement-feature skill
or any other skill.

## The slice
Read <path to the slice file> — that is the slice to build, acceptance
criteria and Gotchas included.

## Cross-cutting constraints
<README § Cross-cutting Constraints, verbatim — omit the section if empty>

## Domain terms
<the term names this slice uses> — defined in <path to CONTEXT.md>; read
those entries before naming anything. Omit if none.

## What previous slices established
Read .scratch/<feature-name>/PROGRESS.md before starting — one handoff note per
slice already built. Slices <the Blocked by list> matter most. Omit for slice 01.

## Where to start
<pointers, one line each. "The pattern to follow is at X." "The API client is
at Y — use apiFetch, not fetch." Each is a starting point, not a guarantee: if
it is not there, search before assuming.>

## Project mechanics
Test command: <exact command and flags>
Type-check: <exact command>
Lint: <exact command, or "none configured">
```

### The handoff note is the point

Keep each returned `## Handoff` block — roughly 15 lines — and append it to `PROGRESS.md` in Step 6. The next subagent reads it from there; do not paste the accumulated notes into each briefing, which grows every dispatch and re-sends them through this context. Keep nothing else from the subagent's reply.

This is what makes delegation worth doing. A single long context gives later slices knowledge of earlier ones for free; naive delegation throws that away and slice 06 re-decides what slice 03 already settled. The handoff note, read from `PROGRESS.md` by the next subagent, buys that continuity back at summary cost instead of transcript cost, and it is a correctness fix as much as a token one.

Two things to do with each note as it arrives:

- **Read `Surprises`.** It is the only channel that corrects your own picture of the codebase. A surprise usually means a `Where to start` pointer was stale, or the plan is drifting from the code — the second is an early-stop trigger.
- **Check `Files touched` against the slice's `Files to create/modify`.** A subagent that wandered outside its list is the main way delegated work goes wrong quietly.
- **When a fix or slice spans layers (e.g. a PHP/backend payload plus a TypeScript/frontend orchestration layer plus tests), confirm every layer was actually updated to match — don't take "tests pass" as proof.** Existing tests only prove what they already cover; a new field or behavior added to one layer but not threaded through the others can pass the full suite while being silently broken end-to-end, if no test exercises the new behavior across all layers. Grep for the new field/function name across the files each layer owns, not just the one the subagent's handoff mentions changing, especially when the handoff describes fixing a "gap" in only one place.

### Reporting

Report to the user in your own words from the handoff note, at the same level of detail you would if you had written the code yourself. Never paste a subagent's reply through, and never describe work as verified until you have re-run the tests here.
