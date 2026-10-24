# ADR 0001: Service taxonomy applied as tags, not as a fixed task list

**Status:** Accepted
**Date:** 2026-09-25

## Context

Estimates and logged actuals were grouped ad-hoc, so two similar jobs could not be compared. A fixed Service > Sub-task taxonomy of ten services was proposed to fix that.

The ten services are marketing-agency shaped. All software work collapses into one of them, "Digital", while the existing anchors break software down into frontend, backend, auth, integrations and migrations. A build estimate needs that detail to be defensible to a client.

## Decision

Task lines stay plain-English free text. Each carries a Service and Sub-task tag, and the report subtotals by Service.

Anchors, archetypes and Harvest actuals are tagged with the same taxonomy, so all four group identically.

## Alternatives Considered

- **A closed menu of Service > Sub-task items as the only task lines.** Maximum consistency, but a whole build compresses into a handful of Digital sub-tasks and the estimate stops being defensible.
- **Two output shapes — menu for non-software jobs, free text for software.** Meets both needs but means one skill maintaining two report formats and two sets of rules.

## Consequences

- Estimates stay as granular as they are today while becoming comparable across job types.
- Every task line now carries two extra fields, which is more for the estimator to get right.
- Changing the taxonomy later invalidates the grouping on every job already logged. The All Jobs page is append-only, so a change means a recorded changeover date, not a rewrite.
- Nine of the ten services have almost no anchors. Tagging makes that gap visible, which is the point, but it means the anchors are not yet useful outside Digital.
