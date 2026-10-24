# /code-review

Analyse the current branch's git changes, summarise what was done, and perform a code review with actionable feedback.

## Pre-flight Check

Before running the code review, validate that the repository is in a valid state:

```bash
bash ~/.claude/commands/code-review/validate-preconditions.sh
```

These scripts live at the user level (`~/.claude/commands/code-review/`). There is no repo-level copy, so a relative path will not resolve — always invoke them via `~`.

This checks:
- Working tree is clean (no uncommitted changes, excluding skill infrastructure files)
- Branch is tracking a remote
- There are commits to review
- Files have changed

Note: The `.claude/commands/code-review/` directory is excluded from the working tree check since it contains skill infrastructure, not user code. Any other uncommitted changes will block the review — commit or stash them before proceeding.

If validation fails, address the issues and re-run before proceeding to the steps below.

## Steps

### 1. Gather metadata

Run the metadata preparation script to extract all necessary information:

```bash
bash ~/.claude/commands/code-review/prepare.sh
```

**First decide what the user asked you to review.** If they named a range, pass it through instead of letting the script auto-detect:

| The user said | Run |
| --- | --- |
| nothing specific — review this branch | `prepare.sh` |
| "review the last 5 commits" | `prepare.sh --last 5` |
| "review up until commit abc123" / "since abc123" | `prepare.sh --since abc123` |
| "review against production" | `prepare.sh --base origin/production` |
| an explicit range | `prepare.sh --range abc123..def456` |

`--last` and `--since` are the normal answer when the user is **on a base branch** such as `master`. Auto-detection cannot know which commits they mean there, so it falls back to comparing against another base branch and says so in `warnings`. Never guess a range — if the user is on `master` and did not say, ask which commits they want reviewed.

This outputs a JSON object containing:
- **branch**: current branch name
- **base_branch**: the ref the review is taken against
- **range_start**: the commit the review starts *after*
- **range_description**: one line stating exactly what is being reviewed — echo this to the user before starting
- **diff_command**: the exact `git diff` to run to see the reviewed changes
- **task_id**: ClickUp task ID extracted from branch name (if `dev/*` pattern)
- **commits**: commits authored in this range, merge commits excluded
- **merge_commits_in_range**: merges found in the range — see below
- **clickup_urls**: all unique ClickUp URLs extracted from commit history
- **changed_files**: list of all files changed
- **file_count**: number of files changed
- **total_changes**: insertion/deletion statistics
- **warnings**: anything the reviewer should know about how the range was chosen — always read these, and surface them to the user

Use this pre-computed metadata for the review — no need to run git commands manually. This reduces token usage and ensures consistency.

**Do not review merged-in code.** The diff is taken from the merge-base of the base ref and HEAD, so work merged *in* from `master` or `production` to bring the branch up to date is already excluded. `merge_commits_in_range` lists the merges that happened. Treat their content as reviewed elsewhere. If a merge came from somewhere other than the base branch, say so in the review rather than silently critiquing that code.

**Use `diff_command` verbatim.** Do not substitute `git diff master...HEAD` or `git diff master HEAD` — the first is right only by coincidence and the second includes everything on master that the branch has not merged.

### 2. Analyse the changes

Read the full diff carefully. For each changed file, note:
- The file's purpose and role in the codebase (read the file if context is needed)
- The nature of the change (new feature, bug fix, refactor, UI change, data flow change, etc.)
- The scope and risk of the change

Use the commit log and ClickUp URLs from the metadata to understand the problem being solved.

### 3. Write the summary

Produce a concise plain-English summary of what this branch does — written for a developer audience (reviewer, team lead, or future maintainer). Cover:
- **What changed** — the key behaviour or feature introduced/fixed
- **Why** — the problem being solved or goal being achieved (infer from the metadata's commit messages and ClickUp task IDs)
- **How** — a brief description of the implementation approach
- **Risk** — overall risk assessment (High / Medium / Low) and a one-sentence justification

### 4. Code review

Review the diff with the eye of an experienced developer. Produce **two separate review sections**:

---

**Section A — Review of changes (primary)**

Focus exclusively on the lines added or modified in the diff. This is the primary review. Ask: is the new/changed code correct, safe, and well-written?

Areas to cover (scoped strictly to the changed lines):
- Correctness: does the changed code do what it intends to do?
- Edge cases: are null/undefined, empty arrays, missing data, and error states handled within the new code?
- Security: are there any injection risks, unvalidated inputs, or exposed sensitive data introduced by the changes? For data export, bulk query, or auth endpoints, also check for missing rate limiting.
- Performance: any unnecessary re-renders, N+1 queries, unthrottled operations, or large payloads introduced?
- Code quality: naming clarity, function size, duplication, and adherence to patterns already used in this codebase — within the changed code only
- Types: are TypeScript types in the new code precise, or are `any` / overly broad types used where stricter types are feasible?
- Tests: are there tests for the changed behaviour? **Always explicitly state whether tests exist or not.** If no tests exist and the change involves security, auth, data mutations, or complex logic, flag this as at least a Minor finding with a recommendation to add tests.

---

**Section B — Observations on existing code (secondary)**

While reading context around the diff, note any pre-existing issues in the surrounding code that are worth flagging — but keep this section clearly separate and lower priority. Only include findings that are meaningfully related to the changed area (i.e. things a reviewer would naturally notice). Do not audit the entire file. Limit this section to at most 5 observations.

---

**Severity levels (apply to both sections):**
- **Critical** — bugs, security vulnerabilities, data loss risks, or anything that will break in production
- **Major** — logic errors, missing edge-case handling, performance problems, or violations of established patterns in this codebase
- **Minor** — style inconsistencies, unclear naming, unnecessary complexity, or small improvements that would aid readability/maintainability
- **Praise** — good practices, clean patterns, or noteworthy decisions worth calling out (Section A only)

For each finding, include:
- The file and approximate line reference
- A clear description of the issue or observation
- A suggested fix or improvement (where applicable)

### 5. Output the report

Print the full report to the conversation using this structure:

```
# Code Review — {branch-name}
**Date:** {YYYY-MM-DD}
**Branch:** {branch-name} (from metadata)
**Base branch:** {base-branch} (from metadata)

## ClickUp Tasks
{bulleted list from metadata.clickup_urls, or "None detected" if none found}

## Summary
**What:** {what changed}
**Why:** {the problem or goal}
**How:** {implementation approach}
**Risk:** {High / Medium / Low} — {one-sentence justification}

## Commits
{commit log from metadata.commits array — one line per commit}

## Review of Changes

### Critical
{findings, or "None" if none}

### Major
{findings, or "None" if none}

### Minor
{findings, or "None" if none}

### Praise
{findings, or "None" if none}

---

## Observations on Existing Code
> These findings relate to pre-existing code in the changed files, not the changes themselves.

{findings using the same Critical / Major / Minor severity labels, or "None" if none worth flagging}

## Merge Checklist
> Required actions before this can be merged safely.

- [ ] All Critical findings resolved
- [ ] All Major findings resolved or accepted with justification
- [ ] Tests added for: {list specific behaviours that lack test coverage, or "N/A — no complex/security-sensitive logic"}
- [ ] {Any other specific pre-merge requirements identified during review, or "None"}
```

Each finding (except Praise) should follow this format:
- **[filename:approx-line]** {Description of the issue}
  - **Suggestion:** {What to do instead, or why this matters}

Praise findings:
- **[filename]** {What was done well and why it's worth noting}
```
