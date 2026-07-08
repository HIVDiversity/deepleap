# Phylogeny + Heatmap Subworkflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up an opt-in `PHYLOGENY` subworkflow that runs the existing (currently unused) `IQTREE` module on a computed MSA and stubs out a downstream per-site-variation heatmap drawing step, so the full MSA → tree → baseline → heatmap channel path is runnable end-to-end today, with real drawing logic deferred.

**Architecture:** New `workflows/phylogeny/main.nf` subworkflow takes a single `(file, meta)` alignment channel (tagged `meta.alignment_type = NT|AA` by the caller) plus a reference channel and a baseline-method string param. It runs `IQTREE` unchanged, picks a baseline via `REFERENCE` (existing `ch_reference_file`), `CONSENSUS` (existing, currently-unused `GET_CONSENSUS` module) or `MINDIST` (new stub module), and joins tree + alignment + baseline by `meta` into a new stub `DRAW_TREE_HEATMAP` module. `MAIN_WORKFLOW` in `main.nf` builds the input channel from `ch_postprocess_nt` and/or `ALIGN.out.aligned_tuple`, gated behind a new `params.build_phylogeny` flag.

**Tech Stack:** Nextflow DSL2, Docker-containerized processes, nf-schema for param validation.

## Global Constraints

- New/changed modules follow the existing one-process-per-`main.nf`, `test.nf`-per-module convention (see `modules/local/iqtree/`, `modules/local/pipeline_utils_rs/consensus/`).
- No nf-test framework is used in this repo; module/subworkflow tests are plain `.nf` smoke-test workflows run directly with `nextflow run <path>/test.nf -profile docker` and eyeballed via `.view()`/exit code — that convention is preserved here.
- Every process needs a `withName`/`withLabel` container entry in `conf/modules.config` — no process runs without one.
- Do not modify `IQTREE` (`modules/local/iqtree/main.nf`), `GET_CONSENSUS` (`modules/local/pipeline_utils_rs/consensus/main.nf`), or `MULTI_TIMEPOINT_ALIGNMENT` — reuse as-is.
- `DRAW_TREE_HEATMAP` and `MINDIST` scripts stay `touch`-only placeholders; no real drawing/mindist logic in this plan.
- AA input to `PHYLOGENY` is `ALIGN.out.aligned_tuple` (raw align-step output), never `POSTPROCESS.out.sample_tuples_aligned_aa`.
- New test fixtures are small synthetic FASTA files checked into each module's/workflow's own directory (deviating from this repo's existing convention of hardcoded absolute paths to the original author's private data, since those paths don't exist in a fresh checkout and these new tests don't need real biological data).
- Verify Nextflow syntax on every touched/new top-level `.nf` file with `nextflow lint <file>` (run from repo root) before each commit.

---

### Task 1: `MINDIST` stub module

**Files:**
- Create: `modules/local/mindist/main.nf`
- Create: `modules/local/mindist/test-data/aligned.fasta`
- Create: `modules/local/mindist/test.nf`
- Modify: `conf/modules.config` (add `withName: MINDIST` block)

**Interfaces:**
- Produces: `MINDIST` process, input `tuple path(aligned_sequences), val(meta)`, output `tuple path("*.fasta"), val(meta), emit: sample_tuple` — identical shape to `GET_CONSENSUS` (`modules/local/pipeline_utils_rs/consensus/main.nf`).

- [ ] **Step 1: Create the test fixture**

Create `modules/local/mindist/test-data/aligned.fasta`:

```
>seq1
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAG
>seq2
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAC
>seq3
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTTGCTAGCTAGCTAGCTAGCTAG
```

- [ ] **Step 2: Write the module**

Create `modules/local/mindist/main.nf`:

```groovy
process MINDIST {
    tag "${meta.sample_id}"

    input:
    tuple path(aligned_sequences), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:
    """
    touch ${meta.sample_id}.mindist.fasta
    """
}
```

- [ ] **Step 3: Register the container in `conf/modules.config`**

In `conf/modules.config`, insert immediately after the `withName: IQTREE` block (currently lines 101-104, ending `ext.args = params.iqtree_args\n    }`):

```groovy
    withName: MINDIST {
        container = "ubuntu:22.04"
    }
```

So the file reads (excerpt):

```groovy
    withName: IQTREE {
        container = "dlejeune/iqtree:2.0.7"
        ext.args = params.iqtree_args
    }

    withName: MINDIST {
        container = "ubuntu:22.04"
    }

    withName: PROBCONS {
```

- [ ] **Step 4: Write the smoke test**

Create `modules/local/mindist/test.nf`:

```groovy
include { MINDIST } from "./main"

workflow {
    def alignment = file("${projectDir}/test-data/aligned.fasta")
    def meta = ["sample_id": "seqtest"]

    def in_ch = channel.of([alignment, meta])

    MINDIST(
        in_ch
    )

    MINDIST.out.sample_tuple.view()
}
```

- [ ] **Step 5: Lint**

Run: `nextflow lint modules/local/mindist/main.nf` (from repo root: `/home/dlejeune/Projects/deepleap`)
Expected: `Nextflow linting complete!` with no errors listed.

- [ ] **Step 6: Run the smoke test**

Run (from repo root): `nextflow run modules/local/mindist/test.nf -profile docker`
Expected: process `MINDIST` completes (exit status 0), and the view output line shows a tuple like `[/path/to/work/.../seqtest.mindist.fasta, [sample_id:seqtest]]`.

- [ ] **Step 7: Commit**

```bash
git add modules/local/mindist/main.nf modules/local/mindist/test.nf modules/local/mindist/test-data/aligned.fasta conf/modules.config
git commit -m "$(cat <<'EOF'
✨ Add MINDIST stub module

Placeholder for a future minimum-distance baseline sequence
calculation, wired up with the same (file, meta) interface as
GET_CONSENSUS so it can slot into the upcoming PHYLOGENY subworkflow.
EOF
)"
```

---

### Task 2: `DRAW_TREE_HEATMAP` stub module

**Files:**
- Create: `modules/local/draw_tree_heatmap/main.nf`
- Create: `modules/local/draw_tree_heatmap/test-data/tree.tree`
- Create: `modules/local/draw_tree_heatmap/test-data/aligned.fasta`
- Create: `modules/local/draw_tree_heatmap/test-data/baseline.fasta`
- Create: `modules/local/draw_tree_heatmap/test.nf`
- Modify: `conf/modules.config` (add `withName: DRAW_TREE_HEATMAP` block)

**Interfaces:**
- Consumes: nothing from Task 1 directly (independent module), but shares the `(file, meta)` shape used throughout.
- Produces: `DRAW_TREE_HEATMAP` process, input `tuple path(tree), path(alignment), path(baseline), val(meta)`, output `tuple path("*.png"), val(meta), emit: heatmap_tuple`.

- [ ] **Step 1: Create test fixtures**

Create `modules/local/draw_tree_heatmap/test-data/tree.tree`:

```
(seq1:0.01,seq2:0.02,seq3:0.015);
```

Create `modules/local/draw_tree_heatmap/test-data/aligned.fasta`:

```
>seq1
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAG
>seq2
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAC
>seq3
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTTGCTAGCTAGCTAGCTAGCTAG
```

Create `modules/local/draw_tree_heatmap/test-data/baseline.fasta`:

```
>reference
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAG
```

- [ ] **Step 2: Write the module**

Create `modules/local/draw_tree_heatmap/main.nf`:

```groovy
process DRAW_TREE_HEATMAP {
    tag "${meta.sample_id}"

    input:
    tuple path(tree), path(alignment), path(baseline), val(meta)

    output:
    tuple path("*.png"), val(meta), emit: heatmap_tuple

    script:
    """
    touch ${meta.sample_id}.heatmap.png
    """
}
```

- [ ] **Step 3: Register the container in `conf/modules.config`**

Insert immediately after the `withName: MINDIST` block added in Task 1:

```groovy
    withName: DRAW_TREE_HEATMAP {
        container = "ubuntu:22.04"
    }
```

- [ ] **Step 4: Write the smoke test**

Create `modules/local/draw_tree_heatmap/test.nf`:

```groovy
include { DRAW_TREE_HEATMAP } from "./main"

workflow {
    def tree = file("${projectDir}/test-data/tree.tree")
    def alignment = file("${projectDir}/test-data/aligned.fasta")
    def baseline = file("${projectDir}/test-data/baseline.fasta")
    def meta = ["sample_id": "seqtest"]

    def in_ch = channel.of([tree, alignment, baseline, meta])

    DRAW_TREE_HEATMAP(
        in_ch
    )

    DRAW_TREE_HEATMAP.out.heatmap_tuple.view()
}
```

- [ ] **Step 5: Lint**

Run: `nextflow lint modules/local/draw_tree_heatmap/main.nf`
Expected: `Nextflow linting complete!` with no errors listed.

- [ ] **Step 6: Run the smoke test**

Run (from repo root): `nextflow run modules/local/draw_tree_heatmap/test.nf -profile docker`
Expected: process `DRAW_TREE_HEATMAP` completes (exit status 0), view output shows a tuple like `[/path/to/work/.../seqtest.heatmap.png, [sample_id:seqtest]]`.

- [ ] **Step 7: Commit**

```bash
git add modules/local/draw_tree_heatmap conf/modules.config
git commit -m "$(cat <<'EOF'
✨ Add DRAW_TREE_HEATMAP stub module

Placeholder for the future tree + per-site-variation heatmap
rendering step. Takes a tree, the alignment it was built from, and a
baseline sequence, and currently just touches a placeholder PNG so
the PHYLOGENY subworkflow's channel path is runnable end-to-end.
EOF
)"
```

---

### Task 3: `PHYLOGENY` subworkflow

**Files:**
- Create: `workflows/phylogeny/main.nf`
- Create: `workflows/phylogeny/test-data/aligned.fasta`
- Create: `workflows/phylogeny/test-data/reference.fasta`
- Create: `workflows/phylogeny/test.nf`

**Interfaces:**
- Consumes: `MINDIST` (Task 1) — `MINDIST(tuple path, val)` → `MINDIST.out.sample_tuple`; `DRAW_TREE_HEATMAP` (Task 2) — `DRAW_TREE_HEATMAP(tuple path, path, path, val)` → `DRAW_TREE_HEATMAP.out.heatmap_tuple`; existing `IQTREE` (`modules/local/iqtree/main.nf`) — `IQTREE(tuple path, val)` → `IQTREE.out.tree_tuple`; existing `GET_CONSENSUS` (`modules/local/pipeline_utils_rs/consensus/main.nf`) — `GET_CONSENSUS(tuple path, val)` → `GET_CONSENSUS.out.sample_tuple`.
- Produces: `workflow PHYLOGENY` with:
  - `take: alignment_tuples, ch_reference, baseline_method`
  - `emit: tree_tuple, baseline_tuple, heatmap_tuple`
  (all three emits are `(file, meta)`-shaped channels, `meta` carrying whatever `alignment_type` tag the caller attached).

- [ ] **Step 1: Create test fixtures**

Create `workflows/phylogeny/test-data/aligned.fasta`:

```
>seq1
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAG
>seq2
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAC
>seq3
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTTGCTAGCTAGCTAGCTAGCTAG
>seq4
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAA
```

Create `workflows/phylogeny/test-data/reference.fasta`:

```
>reference
ATGGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAG
```

- [ ] **Step 2: Write the subworkflow**

Create `workflows/phylogeny/main.nf`:

```groovy
include { IQTREE } from "../../modules/local/iqtree/main"
include { GET_CONSENSUS } from "../../modules/local/pipeline_utils_rs/consensus/main"
include { MINDIST } from "../../modules/local/mindist/main"
include { DRAW_TREE_HEATMAP } from "../../modules/local/draw_tree_heatmap/main"

workflow PHYLOGENY {
    take:
    alignment_tuples // file, meta (meta.alignment_type = "NT" or "AA")
    ch_reference // value channel, raw reference file
    baseline_method // string param: REFERENCE, CONSENSUS, or MINDIST

    main:
    IQTREE(
        alignment_tuples
    )

    if (baseline_method == "REFERENCE") {
        def ch_baseline = alignment_tuples.merge(ch_reference) { sample, ref -> [ref, sample[1]] }
    }
    else if (baseline_method == "CONSENSUS") {
        GET_CONSENSUS(
            alignment_tuples
        )
        def ch_baseline = GET_CONSENSUS.out.sample_tuple
    }
    else if (baseline_method == "MINDIST") {
        MINDIST(
            alignment_tuples
        )
        def ch_baseline = MINDIST.out.sample_tuple
    }
    else {
        error("Unrecognized phylogeny_baseline_method: ${baseline_method}")
    }

    def ch_tree_keyed = IQTREE.out.tree_tuple.map { tree, meta -> [meta, tree] }
    def ch_alignment_keyed = alignment_tuples.map { file, meta -> [meta, file] }
    def ch_baseline_keyed = ch_baseline.map { file, meta -> [meta, file] }

    def ch_heatmap_input = ch_tree_keyed
        .join(ch_alignment_keyed)
        .join(ch_baseline_keyed)
        .map { meta, tree, alignment, baseline -> [tree, alignment, baseline, meta] }

    DRAW_TREE_HEATMAP(
        ch_heatmap_input
    )

    emit:
    tree_tuple = IQTREE.out.tree_tuple
    baseline_tuple = ch_baseline
    heatmap_tuple = DRAW_TREE_HEATMAP.out.heatmap_tuple
}
```

**Note:** Groovy `def` inside an `if`/`else if`/`else` chain is block-scoped, so `ch_baseline` as written above would not be visible outside the chain. Declare it once before the chain and assign inside each branch instead:

Replace the `if`/`else if`/`else` block above with:

```groovy
    def ch_baseline
    if (baseline_method == "REFERENCE") {
        ch_baseline = alignment_tuples.merge(ch_reference) { sample, ref -> [ref, sample[1]] }
    }
    else if (baseline_method == "CONSENSUS") {
        GET_CONSENSUS(
            alignment_tuples
        )
        ch_baseline = GET_CONSENSUS.out.sample_tuple
    }
    else if (baseline_method == "MINDIST") {
        MINDIST(
            alignment_tuples
        )
        ch_baseline = MINDIST.out.sample_tuple
    }
    else {
        error("Unrecognized phylogeny_baseline_method: ${baseline_method}")
    }
```

So the full, corrected `workflows/phylogeny/main.nf` is:

```groovy
include { IQTREE } from "../../modules/local/iqtree/main"
include { GET_CONSENSUS } from "../../modules/local/pipeline_utils_rs/consensus/main"
include { MINDIST } from "../../modules/local/mindist/main"
include { DRAW_TREE_HEATMAP } from "../../modules/local/draw_tree_heatmap/main"

workflow PHYLOGENY {
    take:
    alignment_tuples // file, meta (meta.alignment_type = "NT" or "AA")
    ch_reference // value channel, raw reference file
    baseline_method // string param: REFERENCE, CONSENSUS, or MINDIST

    main:
    IQTREE(
        alignment_tuples
    )

    def ch_baseline
    if (baseline_method == "REFERENCE") {
        ch_baseline = alignment_tuples.merge(ch_reference) { sample, ref -> [ref, sample[1]] }
    }
    else if (baseline_method == "CONSENSUS") {
        GET_CONSENSUS(
            alignment_tuples
        )
        ch_baseline = GET_CONSENSUS.out.sample_tuple
    }
    else if (baseline_method == "MINDIST") {
        MINDIST(
            alignment_tuples
        )
        ch_baseline = MINDIST.out.sample_tuple
    }
    else {
        error("Unrecognized phylogeny_baseline_method: ${baseline_method}")
    }

    def ch_tree_keyed = IQTREE.out.tree_tuple.map { tree, meta -> [meta, tree] }
    def ch_alignment_keyed = alignment_tuples.map { file, meta -> [meta, file] }
    def ch_baseline_keyed = ch_baseline.map { file, meta -> [meta, file] }

    def ch_heatmap_input = ch_tree_keyed
        .join(ch_alignment_keyed)
        .join(ch_baseline_keyed)
        .map { meta, tree, alignment, baseline -> [tree, alignment, baseline, meta] }

    DRAW_TREE_HEATMAP(
        ch_heatmap_input
    )

    emit:
    tree_tuple = IQTREE.out.tree_tuple
    baseline_tuple = ch_baseline
    heatmap_tuple = DRAW_TREE_HEATMAP.out.heatmap_tuple
}
```

- [ ] **Step 3: Write the smoke test (REFERENCE baseline path)**

Create `workflows/phylogeny/test.nf`:

```groovy
include { PHYLOGENY } from "./main"

workflow {
    def alignment = file("${projectDir}/test-data/aligned.fasta")
    def reference = file("${projectDir}/test-data/reference.fasta")
    def meta = ["sample_id": "seqtest", "alignment_type": "NT"]

    def alignment_ch = channel.of([alignment, meta])
    def reference_ch = channel.value(reference)

    PHYLOGENY(
        alignment_ch,
        reference_ch,
        "REFERENCE",
    )

    PHYLOGENY.out.tree_tuple.view { v -> "TREE: $v" }
    PHYLOGENY.out.baseline_tuple.view { v -> "BASELINE: $v" }
    PHYLOGENY.out.heatmap_tuple.view { v -> "HEATMAP: $v" }
}
```

- [ ] **Step 4: Lint**

Run: `nextflow lint workflows/phylogeny/main.nf`
Expected: `Nextflow linting complete!` with no errors listed.

- [ ] **Step 5: Run the smoke test**

Run (from repo root): `nextflow run workflows/phylogeny/test.nf -profile docker`
Expected: pipeline completes successfully (`Completed at:` / exit status 0 in the log), and stdout includes one line each starting `TREE:`, `BASELINE:`, `HEATMAP:`, each containing `[sample_id:seqtest, alignment_type:NT]` and a file path — `TREE:` pointing at a `*.tree*` file, `BASELINE:` at `reference.fasta` (the input reference, since baseline_method is REFERENCE), `HEATMAP:` at a `*.png` file.

If `IQTREE` fails on the 4-sequence fixture (e.g. complains about insufficient variable sites), increase divergence between the fixture sequences in `workflows/phylogeny/test-data/aligned.fasta` (e.g. vary 4-5 positions per sequence instead of 1) and re-run.

- [ ] **Step 6: Commit**

```bash
git add workflows/phylogeny
git commit -m "$(cat <<'EOF'
✨ Add PHYLOGENY subworkflow

Wires MSA -> IQTREE tree inference -> configurable baseline
selection (REFERENCE / CONSENSUS / MINDIST) -> DRAW_TREE_HEATMAP
placeholder into a single subworkflow, ready to be called from
MAIN_WORKFLOW once real heatmap rendering logic exists.
EOF
)"
```

---

### Task 4: Pipeline params (`nextflow.config` + `nextflow_schema.json`)

**Files:**
- Modify: `nextflow.config`
- Modify: `nextflow_schema.json`

**Interfaces:**
- Produces: `params.build_phylogeny` (boolean, default `false`), `params.phylogeny_alignment_type` (string, default `"NT"`, enum `NT|AA|BOTH`), `params.phylogeny_baseline_method` (string, default `"REFERENCE"`, enum `REFERENCE|CONSENSUS|MINDIST`) — consumed by Task 5.

- [ ] **Step 1: Add params to `nextflow.config`**

In `nextflow.config`, immediately after `multi_timepoint_alignment = false` (currently line 59):

```groovy
    multi_timepoint_alignment = false

    build_phylogeny = false
    phylogeny_alignment_type = "NT"
    phylogeny_baseline_method = "REFERENCE"

```

- [ ] **Step 2: Add params to `nextflow_schema.json`**

In `nextflow_schema.json`, inside the `operating_modes` definition (`$defs.operating_modes.properties`), add three new properties. Insert immediately after the existing `"multi_timepoint_alignment"` property (currently lines 86-89):

```json
        "multi_timepoint_alignment": {
          "type": "boolean",
          "description": "This run should produce timepoint-stacked alignments"
        },
        "build_phylogeny": {
          "type": "boolean",
          "default": false,
          "description": "Infer a phylogenetic tree (and, later, a per-site variation heatmap) from the computed alignment(s)"
        },
        "phylogeny_alignment_type": {
          "type": "string",
          "default": "NT",
          "enum": [
            "NT",
            "AA",
            "BOTH"
          ],
          "description": "Which computed alignment(s) to feed into phylogenetic tree inference"
        },
        "phylogeny_baseline_method": {
          "type": "string",
          "default": "REFERENCE",
          "enum": [
            "REFERENCE",
            "CONSENSUS",
            "MINDIST"
          ],
          "description": "How to choose the baseline sequence used for the (future) per-site variation heatmap"
        },
```

- [ ] **Step 3: Validate the JSON is well-formed**

Run: `python3 -c "import json; json.load(open('nextflow_schema.json')); print('OK')"`
Expected: `OK`

- [ ] **Step 4: Validate the schema against nf-schema**

Run: `nextflow run main.nf -profile docker --help 2>&1 | head -60`
Expected: the help text prints without a schema-parsing error (an nf-schema `AbortOperationException` or JSON schema error would appear near the top of output if the new properties were malformed). It will still fail overall for lack of `--samplesheet` etc. — that failure is expected and fine here; only schema-parse errors are being checked for.

- [ ] **Step 5: Commit**

```bash
git add nextflow.config nextflow_schema.json
git commit -m "$(cat <<'EOF'
✨ Add build_phylogeny pipeline params

Adds build_phylogeny, phylogeny_alignment_type, and
phylogeny_baseline_method params (and schema entries) ahead of
wiring the PHYLOGENY subworkflow into MAIN_WORKFLOW.
EOF
)"
```

---

### Task 5: Wire `PHYLOGENY` into `main.nf`

**Files:**
- Modify: `main.nf`

**Interfaces:**
- Consumes: `PHYLOGENY` (Task 3) — `take: alignment_tuples, ch_reference, baseline_method` / `emit: tree_tuple, baseline_tuple, heatmap_tuple`; `params.build_phylogeny`, `params.phylogeny_alignment_type`, `params.phylogeny_baseline_method` (Task 4).
- Produces: `MAIN_WORKFLOW.out.phylogeny_tree`, `MAIN_WORKFLOW.out.phylogeny_baseline`, `MAIN_WORKFLOW.out.phylogeny_heatmap` — new top-level pipeline outputs `phylogeny_tree`, `phylogeny_baseline`, `phylogeny_heatmap`.

- [ ] **Step 1: Add the include**

In `main.nf`, immediately after the `MULTI_TIMEPOINT_ALIGNMENT` include (currently line 30):

```groovy
include { MULTI_TIMEPOINT_ALIGNMENT } from "./workflows/multi_timepoint_alignment/main"
include { PHYLOGENY } from "./workflows/phylogeny/main"
```

- [ ] **Step 2: Extend `MAIN_WORKFLOW`'s `take:` block**

Currently (lines 41-56):

```groovy
workflow MAIN_WORKFLOW {
    take:
    ch_input_files
    ch_reference_file
    ch_refToAdd
    trim_method
    add_ref_before_align
    add_ref_after_align
    multi_timepoint_alignment
    skip_trim
    skip_functional_filter
    functional_filter_method
    ch_aligner
    is_nt_aligner
    ch_panel_alignment
    trim_coords
```

Change to:

```groovy
workflow MAIN_WORKFLOW {
    take:
    ch_input_files
    ch_reference_file
    ch_refToAdd
    trim_method
    add_ref_before_align
    add_ref_after_align
    multi_timepoint_alignment
    skip_trim
    skip_functional_filter
    functional_filter_method
    ch_aligner
    is_nt_aligner
    ch_panel_alignment
    trim_coords
    build_phylogeny
    phylogeny_alignment_type
    phylogeny_baseline_method
```

- [ ] **Step 3: Add the `PHYLOGENY` call in `main:`**

Currently, the multi-timepoint block ends and `emit:` begins like this (lines 133-156):

```groovy
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // MULTI-TIMEPOINT PROCESSING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def ch_multi_timepoint_alignment = channel.empty()
    if (multi_timepoint_alignment) {
        MULTI_TIMEPOINT_ALIGNMENT(
            ALIGN.out.aligned_tuple,
            PREPROCESS.out.sample_tuples_nt,
            PREPROCESS.out.namefile_tuples,
        )

        ch_multi_timepoint_alignment = MULTI_TIMEPOINT_ALIGNMENT.out.sample_tuples_prof_aln_nt
    }

    emit:
    trimmed_nt = ch_pre_process_output
    sample_tuples_aligned_nt = ch_postprocess_nt
    sample_tuples_aligned_aa = ch_postprocess_aa
    functional_filter_reports = PREPROCESS.out.filter_report
    sample_tuples_rejected_nt = PREPROCESS.out.sample_tuples_rejected_nt
    sample_tuples_length_trimmed_nt = PREPROCESS.out.sample_tuples_length_trimmed_nt
    sample_tuples_prof_aln_nt = ch_multi_timepoint_alignment
    pipeline_report = ch_pipeline_report
}
```

Replace with:

```groovy
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // MULTI-TIMEPOINT PROCESSING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def ch_multi_timepoint_alignment = channel.empty()
    if (multi_timepoint_alignment) {
        MULTI_TIMEPOINT_ALIGNMENT(
            ALIGN.out.aligned_tuple,
            PREPROCESS.out.sample_tuples_nt,
            PREPROCESS.out.namefile_tuples,
        )

        ch_multi_timepoint_alignment = MULTI_TIMEPOINT_ALIGNMENT.out.sample_tuples_prof_aln_nt
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // PHYLOGENY
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def ch_phylogeny_tree = channel.empty()
    def ch_phylogeny_baseline = channel.empty()
    def ch_phylogeny_heatmap = channel.empty()
    if (build_phylogeny) {
        def ch_phylogeny_input = channel.empty()
        if (phylogeny_alignment_type == "NT" || phylogeny_alignment_type == "BOTH") {
            ch_phylogeny_input = ch_phylogeny_input.mix(
                ch_postprocess_nt.map { file, meta -> [file, meta + [alignment_type: "NT"]] }
            )
        }
        if (phylogeny_alignment_type == "AA" || phylogeny_alignment_type == "BOTH") {
            ch_phylogeny_input = ch_phylogeny_input.mix(
                ALIGN.out.aligned_tuple.map { file, meta -> [file, meta + [alignment_type: "AA"]] }
            )
        }

        PHYLOGENY(
            ch_phylogeny_input,
            ch_reference_file,
            phylogeny_baseline_method,
        )

        ch_phylogeny_tree = PHYLOGENY.out.tree_tuple
        ch_phylogeny_baseline = PHYLOGENY.out.baseline_tuple
        ch_phylogeny_heatmap = PHYLOGENY.out.heatmap_tuple
    }

    emit:
    trimmed_nt = ch_pre_process_output
    sample_tuples_aligned_nt = ch_postprocess_nt
    sample_tuples_aligned_aa = ch_postprocess_aa
    functional_filter_reports = PREPROCESS.out.filter_report
    sample_tuples_rejected_nt = PREPROCESS.out.sample_tuples_rejected_nt
    sample_tuples_length_trimmed_nt = PREPROCESS.out.sample_tuples_length_trimmed_nt
    sample_tuples_prof_aln_nt = ch_multi_timepoint_alignment
    pipeline_report = ch_pipeline_report
    phylogeny_tree = ch_phylogeny_tree
    phylogeny_baseline = ch_phylogeny_baseline
    phylogeny_heatmap = ch_phylogeny_heatmap
}
```

- [ ] **Step 4: Pass the new params through the top-level `workflow {}` block**

Currently (lines 203-207):

```groovy
    multi_timepoint_alignment = params.multi_timepoint_alignment
    skip_functional_filter = params.skip_functional_filter
    functional_filter_method = params.functional_filter_method
    skip_trim = params.skip_trim
    aligner = params.aligner.toUpperCase()
```

Change to:

```groovy
    multi_timepoint_alignment = params.multi_timepoint_alignment
    skip_functional_filter = params.skip_functional_filter
    functional_filter_method = params.functional_filter_method
    skip_trim = params.skip_trim
    aligner = params.aligner.toUpperCase()

    build_phylogeny = params.build_phylogeny
    phylogeny_alignment_type = params.phylogeny_alignment_type
    phylogeny_baseline_method = params.phylogeny_baseline_method
```

- [ ] **Step 5: Pass the new params into the `MAIN_WORKFLOW(...)` call**

Currently (lines 275-290):

```groovy
    MAIN_WORKFLOW(
        ch_input_files,
        ch_reference_file,
        ch_refToAdd,
        trim_method,
        add_ref_before_align,
        add_ref_after_align,
        multi_timepoint_alignment,
        skip_trim,
        skip_functional_filter,
        functional_filter_method,
        aligner,
        is_nt_aligner,
        ch_panel_alignment,
        trim_coords,
    )
```

Change to:

```groovy
    MAIN_WORKFLOW(
        ch_input_files,
        ch_reference_file,
        ch_refToAdd,
        trim_method,
        add_ref_before_align,
        add_ref_after_align,
        multi_timepoint_alignment,
        skip_trim,
        skip_functional_filter,
        functional_filter_method,
        aligner,
        is_nt_aligner,
        ch_panel_alignment,
        trim_coords,
        build_phylogeny,
        phylogeny_alignment_type,
        phylogeny_baseline_method,
    )
```

- [ ] **Step 6: Add new outputs to `publish:` and `output {}`**

Currently, the `publish:` block (lines 292-300):

```groovy
    publish:
    trimmed_sample_tuples_nt = MAIN_WORKFLOW.out.trimmed_nt
    sample_tuples_aligned_nt = MAIN_WORKFLOW.out.sample_tuples_aligned_nt
    sample_tuples_aligned_aa = MAIN_WORKFLOW.out.sample_tuples_aligned_aa
    functional_filter_reports = MAIN_WORKFLOW.out.functional_filter_reports
    sample_tuples_rejected_nt = MAIN_WORKFLOW.out.sample_tuples_rejected_nt
    sample_tuples_length_trimmed_nt = MAIN_WORKFLOW.out.sample_tuples_length_trimmed_nt
    sample_tuples_prof_aln_nt = MAIN_WORKFLOW.out.sample_tuples_prof_aln_nt
    pipeline_report = MAIN_WORKFLOW.out.pipeline_report
}
```

Change to:

```groovy
    publish:
    trimmed_sample_tuples_nt = MAIN_WORKFLOW.out.trimmed_nt
    sample_tuples_aligned_nt = MAIN_WORKFLOW.out.sample_tuples_aligned_nt
    sample_tuples_aligned_aa = MAIN_WORKFLOW.out.sample_tuples_aligned_aa
    functional_filter_reports = MAIN_WORKFLOW.out.functional_filter_reports
    sample_tuples_rejected_nt = MAIN_WORKFLOW.out.sample_tuples_rejected_nt
    sample_tuples_length_trimmed_nt = MAIN_WORKFLOW.out.sample_tuples_length_trimmed_nt
    sample_tuples_prof_aln_nt = MAIN_WORKFLOW.out.sample_tuples_prof_aln_nt
    pipeline_report = MAIN_WORKFLOW.out.pipeline_report
    phylogeny_tree = MAIN_WORKFLOW.out.phylogeny_tree
    phylogeny_baseline = MAIN_WORKFLOW.out.phylogeny_baseline
    phylogeny_heatmap = MAIN_WORKFLOW.out.phylogeny_heatmap
}
```

And the `output {}` block — currently ends with (lines 339-342):

```groovy
    pipeline_report {
        path { "execution_report/" }
    }
}
```

Change to:

```groovy
    pipeline_report {
        path { "execution_report/" }
    }
    phylogeny_tree {
        path { file, meta ->
            file >> "phylogeny/trees/${meta.sample_id}_${meta.alignment_type}.tree"
        }
    }
    phylogeny_baseline {
        path { file, meta ->
            file >> "phylogeny/baseline/${meta.sample_id}_${meta.alignment_type}_baseline.fasta"
        }
    }
    phylogeny_heatmap {
        path { file, meta ->
            file >> "phylogeny/heatmaps/${meta.sample_id}_${meta.alignment_type}.png"
        }
    }
}
```

- [ ] **Step 7: Lint the full pipeline**

Run: `nextflow lint main.nf`
Expected: `Nextflow linting complete!`, with a file count higher than the pre-change baseline (36, per the last clean lint run before this plan) since `workflows/phylogeny/main.nf`, `modules/local/mindist/main.nf`, and `modules/local/draw_tree_heatmap/main.nf` are now transitively included, and zero errors reported.

- [ ] **Step 8: Sanity-check parameter wiring**

Run: `nextflow run main.nf -profile docker --build_phylogeny --phylogeny_alignment_type BOTH --phylogeny_baseline_method CONSENSUS --help 2>&1 | head -60`
Expected: help text prints without a parameter-parsing/schema error — confirms the three new params and their enum values are accepted by nf-schema. (Full execution still fails past this point for lack of real sample data; that's expected.)

- [ ] **Step 9: Commit**

```bash
git add main.nf
git commit -m "$(cat <<'EOF'
✨ Wire PHYLOGENY subworkflow into MAIN_WORKFLOW

Adds an opt-in build_phylogeny path that feeds the postprocessed
nucleotide alignment and/or raw align-step amino acid alignment into
the new PHYLOGENY subworkflow, and publishes its tree/baseline/
heatmap outputs alongside the rest of the pipeline's results.
EOF
)"
```

---

## Self-Review Notes

- **Spec coverage:** trigger param (Task 4/5), NT/AA input selection incl. AA = raw `ALIGN.out.aligned_tuple` (Task 5 step 3), baseline selection REFERENCE/CONSENSUS/MINDIST (Task 3), `GET_CONSENSUS` reuse (Task 3), new `MINDIST` stub (Task 1), `IQTREE` reuse unchanged (Task 3), `DRAW_TREE_HEATMAP` stub joined by meta (Task 2/3), new params + schema (Task 4), config containers (Tasks 1-2), output publishing with `alignment_type` in path to avoid NT/AA collisions (Task 5 step 6), module/subworkflow tests (Tasks 1-3) — all covered.
- **Deviation from spec called out:** the spec proposed a new `phylogeny_options` schema group; this plan instead adds the three params to the existing `operating_modes` group (Task 4 step 2), where the structurally identical `multi_timepoint_alignment` flag already lives. Same params, same validation behavior, one less `$defs` group and no `allOf` edit needed.
- **Fixed while writing:** the subworkflow's baseline `if`/`else if` chain needed `ch_baseline` declared outside the chain (Groovy block scoping) — corrected in Task 3 Step 2 with the full corrected file shown.
