# Plan: Adopt nf-test for this pipeline

## Context

There is currently no automated test framework. The `test.nf` files scattered
under `modules/local/*`, `subworkflows/local/*`, and `workflows/*` (~30 files)
are manual harnesses: they build an input channel by hand, invoke the
process/workflow, and `.view()` the output. No assertions, not run in CI.
`.github/workflows/ci.yml` only deploys mkdocs — there is no pipeline-testing
CI job today.

Each existing `test.nf` already encodes the correct input shape (channel
structure, meta maps, tuple layouts) for its target, so it doubles as a
spec for the nf-test conversion. `test_data/` and `sample_data/` already hold
small fixtures reused across these manual tests and can seed nf-test
fixtures directly.

Goal: replace the manual `test.nf` harnesses with real nf-test suites
(module, subworkflow, workflow tiers), wired into CI, with meaningful
assertions/snapshots instead of `.view()`.

## Phase 0 — Foundation (spike, ~0.5–1 day)

1. Install nf-test locally, add `nf-test.config` at repo root.
2. Pick **one** representative module to convert end-to-end as the template:
   - `modules/local/pipeline_utils_rs/trim_to_stop` — simple, single process,
     small fast container, already has clear input/output shape from its
     `test.nf`.
3. Write `modules/local/pipeline_utils_rs/trim_to_stop/tests/main.nf.test`
   using `test_data/inputs/sample_a.fasta` as fixture, with real `assert`
   checks on output file content (not just existence).
4. Confirm container pulls and runs locally (`dlejeune/pipeline-utils-rs:4.1.0`).
5. Decide assertion style per tool category now, before scaling out:
   - Deterministic CLI tools (trim/strip/concat/utils) → exact-content
     `assert` on output.
   - Alignment tools with potentially non-deterministic output
     (mafft, muscle, tcoffee, prank, pagan, probcons, iqtree, aga, macse,
     clustal, virulign, viralmsa, minimap2) → nf-test snapshot
     (`nf-test.snap`) with periodic manual review, rather than brittle
     exact-match assertions.
6. Add a `test` (or `nf-test`) CI job to `.github/workflows/ci.yml` (or a new
   workflow file) that installs nf-test and runs the Phase-0 test, to prove
   out container access/caching in GitHub Actions before scaling.

**Exit criterion:** one module test passing locally and in CI, assertion
convention agreed, CI job skeleton in place.

## Phase 1 — Module-tier conversion (bulk, ~3–5 days)

Convert the remaining ~27 module `test.nf` files to nf-test, grouped by
existing groupings to parallelize/parallel-review:

- `pipeline_utils_rs/*` (consensus, extract_seq_from_genbank,
  reverse-translate, translate, trim_sam) — 5 modules, same container family,
  should go quickly once trim_to_stop's pattern is set.
- `utils/*` (add_sequences, concat_fasta, concat_json, mafft_merge_index,
  remove_reference) — lightweight, no exotic containers.
- Alignment tools (mafft, muscle, tcoffee, prank, pagan, probcons, clustal
  omega/w, macse, virulign, viralmsa, minimap2, aga) — heavier containers,
  snapshot-based assertions per the Phase 0 convention.
- `functional_filter`, `seqtk/subseq`, `strip`, `iqtree`, `pipeline_report`.

For each: delete the old `test.nf` once the nf-test replacement is verified
passing (don't keep both — avoid a duplicate/stale test surface).

**Exit criterion:** every module under `modules/local/` has an nf-test suite;
old `test.nf` files removed; CI runs the full module tier.

## Phase 2 — Subworkflow tier (~1–2 days)

Convert `subworkflows/local/{pre_alignment_process,trim_aga,trim_minimap}`.
These chain multiple already-tested processes, so tests here should focus on
channel wiring/branching correctness (right meta propagated, right
branch taken) more than re-verifying tool output.

## Phase 3 — Workflow tier (~2–3 days)

Convert `workflows/{align,multi_timepoint_alignment,postprocess,preprocess}`.
These are the slowest and most integration-heavy (multiple containerized
tools chained). Use `params.aligner` / `params.trim_method` branching in
`nextflow.config` to drive test cases that exercise each code path
(e.g. AGA vs MINIMAP trim; MAFFT vs MUSCLE vs TCOFFEE aligner) rather than
one test per workflow.

## Phase 4 — CI hardening (~1 day)

- Split CI into fast (module) and slow (subworkflow/workflow) jobs if runtime
  becomes an issue; cache pulled containers between runs.
- Gate CI on PRs, not just push to `main` (current `ci.yml` only triggers on
  push to main and only does docs deploy — testing needs its own trigger,
  e.g. `pull_request`).
- Document how to run nf-test locally in `docs/` (mirrors existing
  `docs/usage.md`/`docs/installation.md` structure).

## Total estimate

~1.5–2 weeks for one engineer to reach full module/subworkflow/workflow
coverage with meaningful (non-`.view()`) assertions and CI enforcement.
Phase 0 is the highest-leverage first step — it validates container/CI
mechanics and the assertion convention before ~30 files' worth of
conversion work is committed to a pattern that might need rework.

## Open questions to resolve before/during Phase 0

- Are the alignment tool containers deterministic enough for snapshot
  testing to be stable across CI runs (e.g. thread-count-dependent output
  ordering in mafft)? If not, may need `--thread 1` pinning in test-only
  config or content-independent assertions (e.g. sequence count, header
  presence) instead of full snapshots.
- Should nf-test run against real containers in CI (slow, faithful) or is a
  lighter local/stub mode acceptable for PR-gating, with full-container runs
  nightly/on-merge only?
