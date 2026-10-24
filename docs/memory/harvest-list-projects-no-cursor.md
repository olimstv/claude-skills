---
name: harvest-list-projects-no-cursor
description: Harvest's list_projects MCP tool has no pagination cursor, unlike list_time_entries — it truncates at 100 with no way to page through the rest.
metadata:
  type: convention
---

`mcp__claude_ai_Harvest__list_projects` returns up to 100 rows and reports `truncated: true` when there are more, but it has no `cursor`/`next_cursor` parameter to page with — unlike `list_time_entries`, which does. There is currently no active/inactive split under 100 rows either: this account has 144+ active projects alone.

**Why:** any bulk analysis across all Harvest projects (e.g. archetype seeding, an account-wide audit) silently sees only the first 100 unless the call is narrowed. A `truncated: true` response is easy to miss if you're not checking for it.

**How to apply:** when you need every project, not just a search result, narrow with `client_ids` in batches small enough that no batch's `total_count` exceeds 100 — get the client list from `list_clients` first. Treat `truncated: true` as an instruction to narrow further, never as "good enough." See `job-actuals/SKILL.md` § "Seeding archetypes" Step 1 for the pattern in use.

Related: [[harvest-rates-not-readable]], [[harvest-task-names-are-messy]]
