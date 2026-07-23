---
icon: lucide/monitor
---

# Frontend Guide

> **TODO:** This page is referenced from the homepage ("I'm a lab user" path) but
> doesn't exist yet. It should let a non-CLI user get from zero to a running pipeline
> through the web frontend (`deepleap-frontend`) without ever touching Nextflow
> directly. See [Containerization](../developer-guide/containerization.md) for the
> Docker Compose setup this page should build on top of — that page currently has the
> admin-facing config details; this one should be the task-focused walkthrough.

## Prerequisites

[TODO: what needs to already be running before a lab user opens the frontend —
presumably someone (an admin) has already deployed `deepleap-frontend` per
[Containerization](../developer-guide/containerization.md). Clarify who is
responsible for that deployment step vs. what the end user does.]

## Starting a run

[TODO: walk through the run-creation UI — samplesheet upload, reference selection,
parameter choices exposed in the frontend vs. CLI-only params.]

## Monitoring a run

[TODO: what does run status/progress look like in the UI.]

## Retrieving results

[TODO: where outputs land, how to download them — cross-reference
[Outputs Reference](../reference/outputs.md).]

## Troubleshooting

[TODO: common frontend-specific failure modes (e.g. docker socket permissions,
group ID mismatches) — see the notes in
[Containerization](../developer-guide/containerization.md) for the underlying cause.]
