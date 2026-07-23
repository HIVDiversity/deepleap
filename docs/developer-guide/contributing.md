---
icon: lucide/git-pull-request
---

# Contributing

There's no formal contribution process for this repo yet. If you're planning
anything beyond a small fix, open an issue first to check the approach before
investing time in a PR.

## Development setup

- Clone the repo and work off `main` directly — unlike end users (who are pointed
  at a release tag, see [Installation](../user-guide/installation.md)),
  contributors need the latest module/workflow code.
- You'll need Nextflow and a container runtime (Docker or Singularity), exactly as
  described in [Installation](../user-guide/installation.md).
- For quick iteration on a single module or workflow, `sample_data/` and
  `test_data/` already hold small fixtures you can point a `-params-file` or a
  manual `test.nf` at, rather than running the full pipeline end to end.
- The custom Rust/Python tools (`pipeline-utils-rs`, `rusty-MetAL`,
  `functional-filter`, the pipeline report generator) each live in their own
  repository with their own toolchain. You only need to set those up if you're
  changing the tool itself — from this repo's side, they're just container images
  referenced in `conf/modules.config`.
- The docs site currently has **two** parallel build configs in the repo root —
  `mkdocs.yml` (deployed by `.github/workflows/ci.yml` via `mkdocs gh-deploy`) and
  `zensical.toml` (deployed by a separate GitHub Pages workflow, and still holding
  its default placeholder content). Until one of these is settled on and the other
  removed, `mkdocs serve` against `mkdocs.yml` is the one that reflects real
  content.

## Running tests

There is currently no automated test framework wired into CI — the only CI job
today deploys the docs site. Each module, subworkflow, and workflow directory has
a manual `test.nf` harness that builds an input channel by hand and `.view()`s the
output, but these aren't run automatically and don't make real assertions; some
also hard-code absolute paths from the original author's machine, so don't assume
one will run as-is without adjusting its inputs first.

`llm_plans/nf-test-adoption-plan.md` (in the repo root, not part of this docs site)
lays out a plan to replace these with real [nf-test](https://www.nf-test.com/)
suites, phased by module → subworkflow → workflow tier, wired into CI. That
migration hadn't started as of this writing — check the plan file itself for
current status rather than relying on this page, since this section won't be kept
in lockstep with its progress.

## Adding a new aligner

Using the existing aligners as a template (see [Pipeline
Modules](pipeline-modules.md)), adding a new one touches:

1. **A new module** under `modules/local/<tool>/main.nf`, following the shape
   every other aligner module uses: `tag "${meta.sample_id}"`, a `label` for the
   tool, input `tuple path(sample), val(meta)`, and output
   `tuple path("*.<ext>"), val(meta), emit: sample_tuple`.
2. **A container entry** in `conf/modules.config`, under `withLabel:` (if sharing
   a label with a sibling process) or `withName:` — the image, and resource
   limits (`cpus`/`memory`/`time`). Wire any user-configurable CLI flags through
   `ext.args`, following the `params.<tool>_args` pattern used by the existing
   aligners.
3. **Dispatch in `workflows/align/main.nf`** — add a branch to the `ALIGN`
   workflow's `if (aligner == "...")` chain that calls the new module.
4. **Schema validation** — add the new aligner name to the `aligner` enum in
   `nextflow_schema.json`.
5. **NT vs AA handling** — if the new aligner operates on nucleotide sequences
   directly (like `MACSE` and `VIRULIGN`), add it to the `is_nt_aligner` check in
   `main.nf` so the correct sequence type is routed to `ALIGN`.
6. **Docs** — add a row to the [Aligner Reference](../reference/aligners.md)
   comparison table and a line to [Pipeline Modules](pipeline-modules.md).

## Coding conventions

There's no linter or style guide enforced for the Nextflow code in this repo —
conventions here are implicit in the existing modules rather than written down.
Patterns worth following when adding to them:

- Process names in `UPPER_SNAKE_CASE`, matching the tool they wrap.
- `tag "${meta.sample_id}"` on every per-sample process, for readable logs and
  `-resume` tracking.
- A `label` matching the tool name, used by `conf/modules.config` to attach a
  container and resource limits.
- Sample data threaded as `tuple path(file), val(meta)` throughout — the `meta`
  map carries `sample_id` and whatever else the pipeline or samplesheet attached.
- User-configurable CLI arguments passed through `task.ext.args`, sourced from a
  `params.<tool>_args`-style parameter, rather than hard-coded in the module.

## Release process

This isn't formally documented, so treat the following as inferred from the
commit/tag history rather than a written policy — worth confirming before relying
on it. A release bumps `manifest.version` in `nextflow.config` (semver, no `v`
prefix) and tags that commit with the matching bare version number, e.g. `8.1.0`.
Version bumps are sometimes their own commit (conventionally prefixed 🔖) and
sometimes folded into a feature commit that's tagged directly.

!!! warning "Tag prefix mismatch"
    [Installation](../user-guide/installation.md#3-get-the-pipeline) currently
    tells users to `git checkout vX.Y.Z`, but actual tags in this repo are bare
    (`8.1.0`, not `v8.1.0`). That instruction needs fixing to match.
