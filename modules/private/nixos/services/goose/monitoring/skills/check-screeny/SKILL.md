---
name: check-screeny
description: Investigate Screeny backend and chest-counter health by clan, collector and source.
---
# Screeny health

Start with `query` for `up{job=~"screeny|screeny-chest-counter"}`. Preserve `clan`, `instance`, `collector`, `source`, and `source_id` labels when identifying an affected series. Backend and chest-counter targets are distinct services: one being healthy does not establish that the other works.

Use `list_targets` for scrape errors. Read the generated Screeny dashboard skills through `runbooks_list` and `runbooks_read` for the actual application metric names and expressions. Discover current labels with `label_values` and verify types and units with `metric_metadata`.

Compare a 15-minute window with a previous window. Separate a missing or failed scrape from application errors, inactivity and backlog; do not interpret a zero counter or absent data as successful processing. Use rates for counters, avoid combining clans or sources accidentally, and keep range queries within 600 intervals per series. Report the affected clan/source and evidence before proposing remediation.
