# Plan: Pipeline health fixes (identified 2026-07-02)

## Context

This is a snapshot from a review of the pipeline as of branch
`new-modules-trimming`, commit `372144c` (on top of `main`), done with the
`nextflow` skill + `critical-thinking` skill. It's evidence-based — every
item below was verified against the actual source, not inferred. Re-check
each item's premise before acting on it if much time has passed; see
"Before recommending from memory" style caution — file paths/line numbers
may have shifted.

At the time of writing, `new-modules-trimming` had one untracked, empty
file: `modules/local/pipeline_utils_rs/strip_gap_columns/main.nf` (0 bytes),
suggesting a new gap-stripping module was mid-creation. Nothing to act on
there except: don't be confused if it's still empty later — it means that
work stalled or moved elsewhere.

Also relevant: `llm_plans/nf-test-adoption-plan.md` already exists and
covers the "no automated tests" problem (item 5 below) in detail — don't
duplicate that plan, just execute it.

## Findings, ranked by effort → impact

### 1. `validateParameters()` is commented out — (trivial, high impact)

`main.nf` around line 150 has:
```groovy
// validateParameters()
```
right above `log.info(paramsSummaryLog(workflow))`, with a stale comment
above it: `// TODO: I don't think this is necessary since we have params
checking from the validation pipeline`. That TODO is wrong — nothing else
calls `validateParameters()`. The pipeline has a full `nextflow_schema.json`
(395 lines) and `validation.help.enabled = true` in `nextflow.config`, but
schema validation never actually runs. A typo'd param or wrong type
currently passes through silently instead of failing fast.

**Fix:** uncomment the call, run the pipeline once end-to-end (or with
`-stub-run` if feasible) to see what the schema flags, and reconcile any
drift between `nextflow_schema.json` and the actual `params {}` block in
`nextflow.config`. Expect some schema properties to be missing/stale since
they were presumably never exercised.

### 2. Inconsistent error handling in `workflows/preprocess/main.nf` — (trivial, minor)

Lines ~35-36:
```groovy
println("Preprocessing type not reconized.")
exit(1)
```
This is the only place in the codebase using `println` + `exit(1)` instead
of Nextflow's `error(...)` (used everywhere else, e.g. `main.nf`'s
`region_of_interest`/`sample_base_dir` checks). `exit(1)` from inside a
workflow body doesn't give the same structured failure context as
`error()`. Also fix the typo ("reconized" → "recognized").

**Fix:**
```groovy
error("Preprocessing type not recognized: ${trim_method}")
```

### 3. `TRIM_TO_STOP` module is wired nowhere — (small, needs a decision)

`modules/local/pipeline_utils_rs/trim_to_stop/main.nf` was added in commit
`318978f` ("✨ Added the trim-to-stop functionality") with a working
process and its own manual `test.nf`, but it is not `include`d by
`workflows/preprocess/main.nf`, `main.nf`, or anywhere else. Verified via
`grep -rn "TRIM_TO_STOP" .` (only self-references in its own module dir).

This is either (a) mid-integration and needs to be wired into `PREPROCESS`
or `POSTPROCESS` where stop-codon trimming logically belongs, gated by a
new param (e.g. `params.trim_to_stop` or folded into `skip_trim` logic), or
(b) speculative work that should be removed until there's a concrete use
for it. Left as-is, it's dead code that misleads readers into thinking
stop-codon trimming is active in the pipeline today.

**Recommendation:** resolve this decision before/alongside item 5's Phase 0
(nf-test adoption plan proposes converting `trim_to_stop` as the very first
nf-test template specifically because it's small and low-risk) — deciding
whether to wire it in first means the nf-test suite tests something that's
actually reachable from `MAIN_WORKFLOW`, not an orphan.

### 4. Zero-content untracked module: `strip_gap_columns` — (note only)

See Context above. Not a defect, just flagging so a future session doesn't
mistake it for lost/broken work — it was never written yet as of this
snapshot.

### 5. No automated tests — (medium, high payoff, plan already exists)

`~30` `test.nf` files across `modules/local/`, `subworkflows/local/`,
`workflows/` are manual `.view()` harnesses with no assertions and are not
run in CI. Full remediation plan already written:
**`llm_plans/nf-test-adoption-plan.md`** — Phase 0 through Phase 4, ~1.5-2
weeks estimated. Execute that plan rather than re-deriving one here. Note
its Phase 0 template target (`trim_to_stop`) overlaps with item 3 — resolve
item 3 first.

### 6. CI does nothing but deploy docs — (medium, high payoff)

`.github/workflows/ci.yml` triggers only on `push` to `main` and only runs
`mkdocs gh-deploy`. There is no lint step, no Nextflow syntax check, and
(until item 5 lands) no test execution — and it doesn't even trigger on
pull requests, so nothing gates a broken PR before merge.

**Fix (before nf-test lands):** add a `pull_request`-triggered job that at
minimum does a Nextflow syntax/config sanity check (e.g.
`nextflow config -show` against the repo, or a lint pass) so obviously
broken `.nf` files can't merge silently. After item 5 lands, extend this
job to run the nf-test suite.

### 7. Unpinned container: `niemasd/viralmsa:latest` — (trivial, low-medium)

`conf/modules.config` line ~149. Every other container reference in that
file (17 total, checked via `grep -n container conf/modules.config`) is
version-pinned (e.g. `dlejeune/mafft:7.525`, `biocontainers/clustal-omega:
v1.2.1_cv5`). `viralmsa` is the only one on `:latest`, which breaks
reproducibility for exactly the tool most likely to change silently
upstream.

**Fix:** pin to whatever tagged version is currently resolved by
`:latest` (check `niemasd/viralmsa` tags on Docker Hub / GHCR).

### 8. No retry/backoff strategy for transient failures — (medium effort, do after tests exist)

`nextflow.config`'s top-level `process { errorStrategy = "terminate" }` is
global and unconditional — any transient failure (container pull hiccup,
momentary OOM on a shared HPC node) kills the entire run. Given the
pipeline targets Slurm/ilifu/hex/zoidberg HPC profiles (see `profiles {}`
block), this is a real babysitting cost on long runs.

**Fix:** adopt the nf-core-standard pattern, e.g.:
```groovy
errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
maxRetries = 2
```
possibly combined with a memory/time backoff via `task.attempt`. Do this
after item 5 (tests) exist, since it changes failure semantics and you want
a safety net for regressions it might introduce/mask.

## Suggested order of execution

1 → 4 (trivial fixes, do together in one small PR)
2 (trivial, same PR as 1 is fine)
3 (decide: wire in or remove `TRIM_TO_STOP`)
7 (trivial, unrelated — can happen anytime, even in parallel)
5 + 6 (bundle — CI hardening naturally follows from nf-test adoption; resolve 3 first since it's Phase 0's test subject)
8 (last — depends on test coverage existing to be a safe change)
