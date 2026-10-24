---
name: harvest-rates-not-readable
description: The Harvest MCP does not expose charge rates, so any rate used in this repo is human-maintained and unverified.
metadata:
  type: project
---

The Harvest MCP cannot return a charge rate. Checked 2026-09-24: all 90 active tasks have `default_hourly_rate: null`; every project assignment sampled is `uses_default_rate: true` with `billable_rate: null`; `list_invoices` returns empty for this token.

**Why:** rates live in a project default this MCP does not project, and invoice access is outside the token's scope.

**How to apply:** never claim a rate was confirmed from Harvest. Read it from `job-estimator/rates.md`, and say in any output that it is human-maintained. Do not spend calls re-checking — the gap is in the MCP surface, not in the data.

Related: [[harvest-task-names-are-messy]]
