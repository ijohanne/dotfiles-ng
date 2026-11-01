---
name: check-runekist
description: Investigate Runekist scheduler availability, work queues, and execution failures.
---
# Runekist scheduler health

Start with `query` for `up{job="runekist"}`. The configured instance is `app-srv-00.rbx.fr`; service is `runekist`. A missing series and a value of zero require different investigation: use `list_targets` and check scrape errors before diagnosing application behaviour.

Use `runbooks_list` to find the generated Runekist dashboard skill and read it with `runbooks_read`. Use its real metric names and queries; do not invent scheduler metrics. Resolve variables with `label_values`, verify metric types and units with `metric_metadata`, and use rates for counters.

Compare the last 15 minutes with the previous window. Separate queue growth from execution errors and a stalled scrape. Keep range queries within 600 intervals per series, aggregate before listing individual jobs, and describe affected instances, units, evidence and uncertainty. Recommend operational changes for a human to review; this server provides read-only access.
