# Repo Memory (reference)

Companion to `implement-feature` and `plan-feature`. Read this before writing or updating an entry in `docs/memory/`.

Durable knowledge lives in the repo, not in a per-user store. A convention one person had to learn the hard way should be waiting for the next person who touches that code — including the next agent session, and including a teammate who was not in the conversation where it was discovered.

`docs/memory/` holds it. If the directory does not exist, create it with a `README.md` index.

### Which of the three places a fact goes

| Destination | Holds | Loaded |
| --- | --- | --- |
| `CLAUDE.md` | Rules that bind every session in that scope | Always |
| `docs/CONTEXT.md` | Domain glossary — what a term means in this project | Always |
| `docs/memory/` | Situational conventions and in-flight context | Index always; entries on relevance |

The test for `docs/memory/`: **is it true only when you are touching a particular area?** A rule about DynamoDB helpers matters when you touch DynamoDB and is noise otherwise — memory. A rule about how every file in the repo is formatted matters always — `CLAUDE.md`. If a memory entry turns out to apply to every session, promote it to `CLAUDE.md` and drop the entry.

Never write a fact into two of them. A duplicated rule drifts, and then the repo contradicts itself.

### Entry format

One fact per file, `docs/memory/<kebab-case-name>.md`:

```
---
name: <kebab-case-slug, matching the filename>
description: <one line — this is what a future session reads to decide relevance>
metadata:
  type: convention | context
---

**Why:** <what goes wrong without this>
**How to apply:** <when this bites — the trigger, not a restatement of the rule>

<the fact itself>
```

`convention` = a rule to follow. `context` = in-flight state, an ongoing migration, a known-rough area. Mark in-flight entries with dates in absolute form, and delete them when the work lands — stale context is worse than none.

Then add one line to `docs/memory/README.md`:

```
- [Title](file.md) — hook
```

The index is the whole mechanism. It is read every session; the entries are not. So the hook has to carry enough for a cold reader to know whether to open the file, and the index must never accumulate content of its own.

### Writing entries

Same bar as the retrospective generally: write the principle, not the incident. "Always paginate `s3ListObjectVersions`" is an entry. "Fabian and I hit a bug on Tuesday where the version list was truncated" is a conversation.

Before writing, check whether an entry already covers it — update that file rather than adding a near-duplicate. Delete entries that turn out to be wrong; a memory nobody trusts gets ignored wholesale.

Do not record what the repo already tells you: code structure, git history, anything already in `CLAUDE.md` or an ADR. If a past decision needs preserving and it meets the three-condition ADR gate, it is an ADR, not a memory.

**Never reference `.scratch/` from a memory entry.** These are permanent files and that directory is deleted at the user's discretion — copy the substance across.
