---
name: plan-feature
description: Design a software feature end-to-end before implementation — grill out requirements, write a short feature README, break the work into vertical slices, and capture the rationale in `.scratch/`. This is the entry point for ALL coding work — invoke it whenever the user wants code written or changed, then let it decide whether the work needs planning. Trigger on phrasings like "plan a feature", "write a new feature", "add X to the app", "build me a Y", "let's design Z", "spec this out", "break this into tickets", "what's the architecture for", "I want to think this through first", and equally on "fix this bug", "implement a fix", or "refactor Z". Small work is not an exception: this skill routes it straight to `implement-feature` Lightweight Mode. Never invoke `implement-feature` directly in place of this skill.
---

# Plan Feature

Design a feature from requirements through slice breakdown, with all documentation saved to `.scratch/` for handoff to the `implement-feature` skill.

## When to use this skill

Trigger on any request to write or change code. Common surface phrasings:

- "plan a feature" / "let's design X" / "spec this out"
- "write a new feature" / "add X to the app" / "build me a Y"
- "break this into issues" / "split this into tickets"
- "what's the architecture for…"
- "I want to think this through before I build it"
- "fix this bug" / "implement a fix" / "refactor Z"

**Opening ask.** When the request is too thin to size and you have to ask what the work is, close with a hint rather than a second question:

> "Describe what you want to build. If there's a ClickUp card for it, paste the link and I'll read it first."

A hint, not a question — it needs no answer, so it costs nothing on a bug fix and surfaces the card before sizing on a real feature. Never repeat it, and never ask for the card here as a question of its own: Phase 0 does that, once, and only for work that reaches it.

**This skill is the only entry point for coding work.** Never invoke `implement-feature` directly on your own judgement — it is reached through this skill, or through the user running `/implement-feature`. Sizing the task is this skill's job, and it happens after the first look at the request, not before.

Sizing rule: if the requirements are already settled and the change is small, route to `implement-feature` (see below). If the requirements are unclear or the work spans multiple slices, plan it here.

### Small tasks: route, don't bail

Bug fixes, small refactors, and one-off scripts don't need the planning scaffolding (README, slices, grill session) — the overhead gets in the way. But "skip the scaffolding" does NOT mean "work ad-hoc". When you judge a task too small for this skill:

1. Tell the user: "This looks like a small change that doesn't need full planning — I'll follow the lightweight implementation workflow instead."
2. Invoke the `implement-feature` skill and follow its **Lightweight Mode** section (TDD tracer bullet, test conventions, verification, type-check, lint) for the change.
3. If genuinely unsure whether the task is small or feature-sized, ask the user rather than guessing.

Route straight away. Do not run Phase 0 first — a small change needs no ClickUp card, because it produces no planning docs to archive.

Never conclude "this doesn't need plan-feature" and then proceed without loading `implement-feature` — the engineering practices in that skill apply to changes of every size.

## Quick Start

1. Once the work is sized as feature-sized: fold a ClickUp card question into the first grill question, and read the card if there is one.
2. Ask the user to describe the feature.
3. Grill on requirements, edge cases, and constraints — one question at a time.
4. Ask: "Is there anything else, or are you happy for me to start writing the documentation?" Loop until the user explicitly clears you to proceed.
5. Produce `.scratch/feature-name/`:
   - `README.md` — problem, solution, scope, cross-cutting constraints
   - `DECISIONS.md` — grill Q&A and rationale
   - `slices/01-*.md` … `slices/0N-*.md` — vertical slices, each starting with `Status: pending`, a `Complexity` score, and an `MCP` line
6. Update `CONTEXT.md` inline as domain terms resolve, and write `docs/memory/` entries for constraints that only bite in one area.
7. Create ADRs in `docs/adr/` only when the three-condition gate (below) is met.
8. Offer to zip `.scratch/feature-name/` and attach it to the ClickUp card.
9. Close by telling the user the exact command to paste into a new chat.

If the project has no `.scratch/`, `CONTEXT.md`, or `docs/adr/` yet, create them as needed. `.scratch/` lives at the project root; `CONTEXT.md` goes in `docs/` if that directory exists, otherwise at the project root; ADRs live in `docs/adr/`. Don't ask permission — these are the conventions this skill assumes, and committing to them early is part of the value.

## Writing rules (all generated docs)

Apply to every file this skill writes:

- **Bullets by default.** Use prose only where a bullet cannot carry the logic.
- **One idea per sentence.** Max 20 words. Active voice, present tense.
- **No rationale padding.** State the decision. Give the reason only where a reader would otherwise ask "why?".
- **One term, one meaning.** Use the `CONTEXT.md` term, never a synonym.
- **Cut hedges and intensifiers** — "generally", "it's important to note", "quite", "in order to", "we should consider".
- **Say each thing once.** Feature-level *what* lives in `README.md`; slice-level *what* lives in the slice that owns it; *why* lives in `DECISIONS.md`. Never aggregate the slices back into the README.

Respect the length budget on each doc below. Prefer a doc that looks too short — the implementer reads code, not prose.

## Workflow

### Phase 0: Establish the ClickUp Card

**Runs only after sizing, and only for work being planned here.** Anything routed to `implement-feature` skips this phase entirely — never ask a user about a ClickUp card for a bug fix. Those changes produce no `.scratch/` directory, so there is nothing to archive at the end and nothing the question can buy.

**Never spend a round trip on it.** The card question rides along with something you were going to say anyway:

- **The user has already described the feature** — the common case. Bundle it with the first grill question: *"Is there a ClickUp card for this? And [first real question]."* Read the card before question two.
- **The request was too thin to size** — the opening ask already carried the hint, so the user has either pasted a link or not. Do not ask again.
- **A URL or branch ID is already in front of you** — do not ask at all. Confirm what you found: name the card, show the URL, let the user correct you.

Bundling bends the one-question-at-a-time rule of Phase 1, deliberately. That rule protects design questions, where each answer shapes the next; a card lookup competes with none of them and answers in three words. A standalone question here buys nothing the bundled one doesn't.

Get it early, not late. The card carries requirements the user will not think to repeat — a description, acceptance criteria, and comments where the real brief often lives. It also settles the upload target in Phase 6 without a second round of questions. And a user describing a feature from memory rarely mentions the card unprompted, which is exactly why the skill has to ask rather than wait.

**If a card exists:**

1. `clickup_get_task(task_id, include: ["description", "custom_fields", "attachments", "subtasks"])`
2. `clickup_get_task_comments(task_id)` — requirements agreed after the card was written live here, not in the description.
3. Read both before your next grill question, then grill on what they leave open. **The card is input, not a substitute for the grill.** Cards are thin and go stale; the user's answers win wherever the two conflict, but name the conflict rather than silently picking a side.
4. Record the URL under `README.md` § References, and carry the task ID to Phase 6.

**If there is no card,** say nothing further about it and start the grill. Phase 6 asks once more at the end — cards are often created during planning, or the user remembers one later.

**Branch hint.** `git rev-parse --abbrev-ref HEAD` sometimes carries the task ID (`feature/new-checkout-86d45tbj6`, `86d45tbj6-fix-totals`). It can sit anywhere in the name, so scan the whole thing for a segment shaped like a ClickUp ID (`86d45tbj6`) or a custom ID (`DEV-1234`). Finding nothing is the normal case — features are routinely planned before the branch exists, and branch names follow no reliable convention. Treat any hit as a candidate to confirm with the user, never as established fact.

A ClickUp task URL is `https://app.clickup.com/t/{workspace}/{task_id}` or `https://app.clickup.com/t/{task_id}` — the trailing segment is the task ID.

### Phase 1: Grill Session

Ask one question at a time. Wait for the answer before the next question. The single exception is Phase 0's card question, which rides along with the first one. Cover:

- Requirements and user flow
- Edge cases and error scenarios
- Constraints (performance, compliance, deadlines)
- Design decisions (UX, architecture, API surface)
- Dependencies on existing systems

If `docs/CONTEXT.md` exists, load it; otherwise check for `CONTEXT.md` at project root. Challenge terminology against it. If the user uses a term that means something different in this project's glossary, surface the conflict — don't paper over it. Update the glossary inline as terms resolve.

**Know when to stop.** One question at a time is right, but the grill is not open-ended — it ends when you can write the slices, not when you run out of curiosity. Move to the readiness check as soon as either is true:

- Three consecutive answers add nothing that would change a slice. The user is confirming what you already knew.
- You could write the slice list right now and would not have to guess at any of it.

Read `docs/memory/README.md` before the grill starts, and open any entry whose hook touches the area this feature affects. It is the cheapest source of the constraints a teammate already discovered, and it stops you asking the user something the repo has recorded. A question you can answer yourself by reading the code or the memory index is not a question for the user. Check the code first, then ask only about what the code cannot tell you: intent, priorities, and trade-offs.

Grilling past this point feels thorough and is not. It spends the user's patience on detail that never reaches a slice, and it front-loads decisions better made against real code.

### Phase 1.5: Readiness Check (MANDATORY — loop until cleared)

Before writing any documentation, ask:

> "Is there anything else, or are you happy for me to start writing the documentation?"

**Wait for the response. Do NOT start writing docs yet.**

- If the user raises anything new — answer it, address it, ask any necessary follow-up questions, then ask the readiness question again.
- If the user says "yes", "go ahead", "proceed", "write it", "start", "that's everything", or similar confirmation — proceed to Phase 2.
- If the response is ambiguous — treat it as a new point and respond to it before asking again.

Users often think of something right after pressing Enter, so one pause isn't enough. Never infer clearance from silence or a short reply.

### Phase 2: Write the README

Save to `.scratch/feature-name/README.md`. This is the only feature-level doc — the user reads it top to bottom before touching the slices. **Budget: 1 page.**

**The test that decides what goes in here: will a specific slice restate this?** If yes, it belongs in that slice, not here. Do not aggregate the slices — no combined file list, no per-module implementation notes, no per-slice test plans. Those get written once, in the slice that owns them.

```
# [Feature Name]

## Problem
[Max 3 bullets. The problem, from the user's perspective.]

## Solution
[Max 3 bullets. The solution, from the user's perspective.]

## Out of Scope
[Bullets. Explicitly what is NOT being built.]

## Cross-cutting Constraints
[Bullets. Only rules that bind EVERY slice — an error-handling convention, a
performance ceiling, a compatibility guarantee, an API style the codebase
already enforces. Omit the section if there are none. Do not list project-wide
testing conventions here; `implement-feature` already specifies them.]

## Acceptance Criteria
[Feature-level definition of done, checked at end-to-end verification after all
slices land. Not a merge of the slice-level criteria.]
- [ ] Must-have behaviour 1
- [ ] Must-have behaviour 2

## References
[Links to ADRs, glossary entries, legacy code, prior features. Include the
ClickUp card URL if the work has one.]
```

Do not include specific file paths or code snippets in the README — they go stale fast and belong in the slices. Exception: if a prototype produced a snippet that precisely encodes a cross-cutting decision (state machine, schema, type shape), inline it and note it came from a prototype.

### Phase 3: Capture Decisions

Save to `.scratch/feature-name/DECISIONS.md`. This is the only doc that carries *why*. **Budget: 4 lines per decision.**

```
### Q1: API endpoint
**Decision:** Use `/api/endpoint`
- **Why:** Existing endpoint already used by legacy app
- **Implication:** No client-side transformation needed
- **Alternatives considered:** New `/v2/endpoint` — rejected because legacy clients can't migrate this quarter
```

Also capture, as bullets:

- Key assumptions
- Trade-offs explicitly considered
- Updated `CONTEXT.md` entries (just the new terms, with definitions)

Write enough that someone can reconstruct the reasoning in six months without re-running the grill. No more.

### Phase 4: Slice Breakdown

Break the work into **vertical slices** — narrow but complete paths through every layer (schema → API → UI → tests), each demoable on its own. Horizontal slices (e.g., "all the schemas first", "all the components") produce piles of half-done plumbing and nothing shippable until the very end.

Vertical slice rules:

- Each slice cuts end-to-end through all relevant layers
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones — granularity is cheap, regret is expensive

#### Slice file format

Save each as `.scratch/feature-name/slices/0N-short-name.md`. **Budget: 1 page.**

```
Status: pending
Complexity: 5 (design 2, scope 1, tests 1, hazards 1)
MCP: none

# [Short title]

## What to build
[Max 3 bullets. End-to-end behaviour for this slice. What the user or caller
can do once it's done — not which files change.]

## Files to create/modify
- path/to/file.ts
- path/to/other.tsx

## Test approach
[Bullets. Which behaviours to test, how to verify the slice works.]

## Acceptance criteria
- [ ] Behaviour 1
- [ ] Behaviour 2

## Blocked by
[Slice numbers this depends on, or "None — can start immediately".]

## Gotchas (omit if none)
[Bullets. Only what would bite the implementer on THIS slice: ordering hazards,
custom hooks/wrappers that shadow library methods, test setup quirks, external
blockers, docs already updated during planning. Facts that apply to the whole
feature belong in `README.md` § Cross-cutting Constraints, not here.]
```

The `Status:`, `Complexity:` and `MCP:` lines at the top are a contract with the `implement-feature` skill. Always write `Status: pending` when planning — it is the only value this skill ever writes. `implement-feature` moves it through the rest of the lifecycle:

```
pending  →  in-progress  →  done
```

`in-progress` means a slice is being built right now, or was abandoned part-built when a session ended. Either way it is the first thing anyone picks up.

`Complexity` tells `implement-feature` how much model and reasoning effort to spend on the slice. Keep all three fields exactly as written, lower-case, one per line — downstream tooling parses them literally.

`MCP` tells `implement-feature` which subagent can build the slice. Its lean subagent has only file and shell tools, so a slice that needs an MCP server goes to one that has them. Write `MCP: none`, or the server names, comma-separated — e.g. `MCP: figma` or `MCP: clickup, google-docs`. List a server only when the implementer must **call** it while building: fetching a Figma frame to match, reading a ClickUp card, checking a live service through its connector. Writing code that is or wraps an MCP server is `MCP: none`. When unsure, list it — a needless listing costs a few thousand tokens, a missing one costs a failed dispatch.

#### Scoring complexity

Score each slice on four categories, 0–2 each. The total (0–8) is the `Complexity` score. Write the breakdown after it, in the same order, so a reader can see which category drove the score.

| Category | 0 | 1 | 2 |
| --- | --- | --- | --- |
| **design** — judgement calls the implementer must make | Fully specified; mirrors existing code. Config, constants, boilerplate, doc updates. | Real naming, structure, and API-shape decisions inside patterns the codebase already has. | Novel design: state machines, auth or permissions, concurrency, data migration, a new module boundary. |
| **scope** — how much it touches | 1–2 files | 3–5 files | 6+ files, or crosses layers (e.g. backend payload and frontend UI) |
| **tests** — how hard it is to test | An existing test pattern applies as-is. | Needs new fixtures, or a new mock at a system boundary. | Unusual setup: time, concurrency, external processes, interactive CLIs, no existing harness. |
| **hazards** — what bites the unwary | Well-trodden code, no `Gotchas`. | `Gotchas` or `docs/memory/` entries apply, but they're straightforward. | Shadowed wrappers, ordering hazards, an area mid-migration, or one an earlier slice was surprised by. |

Score by risk, not by lines produced: a 400-line config table is `design 0`. `implement-feature` owns the mapping from score to model and effort, so never name a model here.

Format, exactly — downstream tooling checks that the breakdown sums to the total:

```
Complexity: 5 (design 2, scope 1, tests 1, hazards 1)
```

**When in doubt, score the category up.** A slice scored too high costs tokens. A slice scored too low costs a debugging session, which costs more.

#### Finalise without asking

Decide granularity, dependencies, and blockers yourself using the slice rules above. Do not ask the user to approve the breakdown — the grill session already gave you what you need, and a second round of questions at this stage just stalls the handoff.

Write the slices, then state the final list in your closing message so the user can see what they got. If you hit a genuine fork that would change the shape of the work, pick the option that keeps slices thinner and note the alternative in `DECISIONS.md`.

### Phase 5: Update Project Docs

#### CONTEXT.md

Add new domain terms as they resolve during the grill. Each entry:

- **Definition** — how the term is used in this project
- **Boundary** — what it is and isn't

Only add terms meaningful to domain experts. Don't couple to implementation details.

If `CONTEXT.md` doesn't exist yet, create it in `docs/` if that directory exists, otherwise at the project root. Use a `# Glossary` header and start adding entries.

**Never reference `.scratch/` from anything permanent.** The user deletes `.scratch/feature-name/` whenever they choose, without warning — any path pointing into it is a broken link waiting to happen. This binds every permanent artefact the work touches: `CONTEXT.md`, ADRs, `CLAUDE.md`, README files, code comments, and commit messages. If one of them needs something from the grill, copy the substance across; never point at `DECISIONS.md` or a slice file by path. This applies to `implement-feature` too.

The reverse direction is fine and expected: docs inside `.scratch/` link out to ADRs and glossary entries freely.

#### docs/memory/

Repo memory holds situational conventions and in-flight context — facts true only when you are touching a particular area. During the grill the user will state constraints that are neither glossary terms nor architecture decisions: an ordering hazard, a tool that must be run a particular way, an area mid-migration. Those are memory entries.

Write them as the grill surfaces them, one fact per file in `docs/memory/`, and add a one-line hook to `docs/memory/README.md`. `~/.claude/commands/implement-feature/reference/repo-memory.md` carries the frontmatter format and the rule for choosing between `CLAUDE.md`, `CONTEXT.md`, and `docs/memory/`. Create the directory and index if the repo has neither.

This is repo-level and shared deliberately. Anything worth remembering about this codebase belongs where the next person to touch it will find it — not in a per-user store that leaves with whoever wrote it.

#### docs/adr/

Create an ADR only when **all three** are true:

1. **Hard to reverse** — changing your mind later has meaningful cost.
2. **Surprising without context** — a future reader will ask "why did they do it this way?"
3. **Result of real trade-off** — genuine alternatives existed and you picked one for reasons.

If any one is missing, skip the ADR — log it in `DECISIONS.md` instead.

Format:

```
# ADR 000N: Title

**Status:** Accepted
**Date:** YYYY-MM-DD

## Context
[Background and the problem.]

## Decision
[What was decided and why.]

## Alternatives Considered
[Other options and why they were rejected.]

## Consequences
[Implications, including downsides.]
```

If `docs/adr/` doesn't exist, create it. Link each ADR from `README.md` § References and from any slice it constrains.

### Phase 6: Offer to Archive the Plan on ClickUp

The planning docs live in `.scratch/`, which the user deletes whenever they choose. If the work has a ClickUp card, a zip of the directory attached to that card is the only durable copy — six months later it is how anyone recovers the plan a feature was built from.

**The card is already known, or already ruled out** — Phase 0 asked at the start. Do not repeat that search here.

**Ask exactly one question, always.** The offer is unconditional — every plan gets it.

Card known:

> Would you like to upload a zip of the plan to ClickUp card **{card title}**?
> https://app.clickup.com/t/{workspace}/{task_id}

No card established in Phase 0:

> Is there a ClickUp card a zip of the plan should be uploaded to?

Ask this even when the user said "no card" at the start. Cards get created once the shape of the work is clear, and this is the last moment the plan can be archived before `.scratch/` becomes its only copy. One line, asked once — if the answer is still no, drop it.

Always print the full URL on its own line, unshortened and unlinked-text — the user clicks it to check you found the right card. Accept three answers: yes, no, or a different URL. **"No" is a normal answer** — go straight to Phase 7 without comment or a second offer.

**If the user says yes:**

1. Zip the directory from `.scratch/`, writing the archive to a temp directory. Never write it inside `.scratch/` — the next zip would pick up the last one.

   ```bash
   ZIP="$(mktemp -d)/{feature-name}-plan.zip"
   (cd .scratch && zip -r "$ZIP" {feature-name})
   echo "$ZIP"
   ```

2. Call `clickup_request_attachment_upload(task_id, file_name: "{feature-name}-plan.zip")`. It returns a short-lived upload URL, ticket, HTTP method, and multipart field name. Follow those instructions with `curl` — do not use `clickup_attach_task_file`, which only takes base64 under ~200KB or a public web URL.

3. Report the result in one line, with the card URL. If the upload fails, say so plainly, print the path to the zip so the user can drag it onto the card by hand, and do not retry silently.

Attach the zip and nothing else. Do not edit the card description and do not post a comment — the plan is a record, not a change to the brief. Re-running this on the same card adds a second attachment rather than replacing the first; if that happens, say so.

### Phase 7: Close

After writing all docs, close with the final slice list (one line each: number, title, blocked-by) followed by this message (substituting the real feature directory name):

> All planning docs are saved. In a new chat, run:
> `/implement-feature .scratch/feature-name/`

This gives the user a single line they can cut and paste to kick off implementation in a fresh context.

## Directory Structure

```
.scratch/feature-name/
├── README.md
├── DECISIONS.md
├── PROGRESS.md              # created by implement-feature, not by this skill
└── slices/
    ├── 01-short-name.md     # Status: pending / Complexity: 1 (design 0, scope 1, tests 0, hazards 0) / MCP: none
    ├── 02-short-name.md     # Status: pending / Complexity: 4 (design 1, scope 1, tests 1, hazards 1)
    └── 0N-short-name.md     # Status: pending / Complexity: 7 (design 2, scope 2, tests 1, hazards 2)
```

## Philosophy

- **One question at a time.** Each answer changes the next question. Batching makes the user answer vague high-level questions and miss the sharp follow-ups — you get docs that look complete but are hollow.
- **Challenge terminology.** If the glossary says X means Y but the user seems to mean Z, name the conflict early — it's much cheaper to resolve before the docs are written than after.
- **Update docs as you go.** `CONTEXT.md` and `DECISIONS.md` get sloppy or forgotten when batched to the end.
- **Sparse with ADRs.** The three-condition gate is what keeps them worth reading. A repo full of low-stakes ADRs trains everyone to ignore them.
- **Vertical slices.** Each slice is a complete path through all layers, not a layer unto itself.
- **Concrete examples.** Use specific scenarios to probe edge cases — abstract questions get abstract answers.
- **Cross-reference with code.** If the user states how something works, check the code agrees. Surface contradictions before they make it into the docs.
- **Brevity is a feature.** Long docs hide the decisions inside them. Every doc this skill writes should read like a checklist, not an essay.
