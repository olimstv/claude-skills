# Finishing a Feature (reference)

Companion to `implement-feature` full mode. Read this once every slice is `done`: Phase 3 end-to-end verification, then the Phase 4 retrospective.

### Phase 3: End-to-End Verification
 
Once all slices are complete:
 
**Every claim in this phase needs evidence in the transcript.** This is the phase most likely to be reported as done without being done, because the steps are slower and less scriptable than running a unit test. The rule: if you cannot point at output you produced, you did not verify it — say it is outstanding instead.

- Verify the full feature works end-to-end (not just unit-tested in isolation). Show the command and its output.
- **Exercise the running app.** Launch it and drive the actual UI — a browser, a simulator, the real CLI. Use the `run` skill if the project has one, or the project's documented start command otherwise. Evidence is a screenshot or the captured session output. If you cannot launch it in this environment, say exactly that and list the steps the user needs to run by hand. Never write "verified in the app" on the strength of passing tests.
- **Check coverage against the project standard** (an ADR or convention may set one, e.g. 100% lines). Evidence is the coverage number. If the project has no coverage tooling wired up, say so rather than estimating.
- **CI-only failures:** if a CI/CD step (build, lint, deploy) fails in a way that doesn't reproduce locally, reproduce it in an environment matching CI (e.g. the same container image) before changing anything. Guessing at a fix from the error message alone risks a push-fix-push-fix cycle; reproducing first turns it into a single, verified fix.
- **No permanent file may reference `.scratch/`.** Run the check; do not eyeball it:
  ```bash
  bash ~/.claude/commands/implement-feature/check-scratch-refs.sh
  ```
  It scans tracked files, uncommitted new files, and this branch's commit messages, and exits non-zero with the offending lines. The user deletes those directories whenever they choose, without warning — anything pointing into one is a broken link waiting to happen. Grep every file the feature created or edited outside `.scratch/` for `.scratch` and for other ephemeral paths (`tmp/`, `scratchpad/`). This covers docs, ADRs, `CONTEXT.md`, code comments, test fixtures, and commit messages. Where a reference exists, copy the substance across into the permanent file and delete the pointer. Never resolve it by leaving the path and hoping the directory survives.

Close the phase with the context size from `context-usage.sh`, alongside the verification results, so the user knows what the retrospective would cost to continue in this session.

### Phase 4: Retrospective

Start from the candidates you collected during Phase 2 (`full-mode.md` § Retrospective notes). The `Surprises` lines already in `PROGRESS.md` cover much of it, and are the only part that survives if this session is resumed in a fresh context — start there.

**If this session started mid-feature** — resumed after a `/clear` at a context checkpoint, or after an auto-compact — then `PROGRESS.md` is not a supplement to your recollection, it is the whole record for every slice you did not personally build. Pull the `Surprises` line of every slice — `grep -A0 '^- Surprises' .scratch/feature-name/PROGRESS.md`, not a full read — and write the retrospective from those plus what happened in this session. Do not present findings from slices built before the clear as though you watched them happen, and say plainly which slices you have no first-hand account of; the user can fill in what matters to them.

Then, after end-to-end verification, do not ask an open-ended question. **Name the two or three strongest candidates and ask about those:**

> "Two things came up that are worth writing down: [X], and [Y]. Want me to add them to [the specific file]?"

A specific offer gets a decision; "would you like a retrospective?" gets declined by a user who is finished and wants to leave. If nothing worth writing down came up, say that in one line and skip the phase — an empty retrospective is a real outcome, not a failure.

If the user agrees:
- Group findings into categories:
  - **Skill improvements** — changes to `plan-feature` or `implement-feature` SKILL.md (e.g. a missing step, a checkpoint that should exist). **Skill changes must be general — applicable to any project, not just this one.** Strip out project-specific details; capture only the underlying principle.
  - **Project conventions** — additions to `frontend/CLAUDE.md`, `backend/CLAUDE.md`, or root `CLAUDE.md`
  - **Domain knowledge** — additions or corrections to `docs/CONTEXT.md`
  - **Architecture decisions** — new ADRs in `docs/adr/` (only when the three-condition gate is met: hard to reverse, surprising without context, genuine trade-off)
  - **Repo memory** — situational conventions and in-flight context, written to `docs/memory/`. Read `~/.claude/commands/implement-feature/reference/repo-memory.md` for the format and for what belongs here rather than in `CLAUDE.md` or `CONTEXT.md`.
- Write proposed additions in short, general language — 2–3 bullets stating the principle, generalized beyond the triggering incident (e.g. a test-mock hang becomes "guard against hangs in any command, script, or tool run"). The incident itself belongs in the conversation as motivation, not in the written note.
- Present the proposed changes to the user before writing anything
- Apply the ones the user approves, to both the user-level skill files (`~/.claude/commands/`) and the repo-level copies (`.claude/commands/`) if both exist
- **Never write a path into `.scratch/` in any of them.** Copy the substance across instead — the planning directory is deleted at the user's discretion and any pointer into it will break.

The goal is compounding improvement: each feature implementation leaves the project better documented than it found it, so the next one requires less human guidance.
