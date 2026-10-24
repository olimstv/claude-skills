---
name: clickup-harvest-no-link
description: Nothing joins a ClickUp card to a Harvest project, so past-job matching needs human confirmation.
metadata:
  type: project
---

ClickUp cards and Harvest projects share no identifier. Harvest projects are named by client and job code (`[VAR] MappedIn Integration`, `ACMA135`), and names repeat across clients and years — four separate clients have a project called `2025 Season`.

**Why:** the two systems were adopted independently and neither carries the other's ID.

**How to apply:** never match a ClickUp card to a Harvest project automatically. Search by client and keyword, present candidates with their hours, and have a person confirm before calibrating against them. Disambiguate by client and date range, never by project name alone.

Related: [[harvest-task-names-are-messy]]
