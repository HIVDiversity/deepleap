# Per-file Step Skipping with Group Merging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let each samplesheet row declare that its file skips trimming and/or functional filtering, while files sharing a `group` are merged back together — before filtering and before alignment — into a single alignment.

**Architecture:** A new dedicated `group` column plus two boolean columns (`skip_trim`, `skip_filter`) drive per-file routing inside `PREPROCESS`. Files are trimmed per-file, then group members are reunited at two boundaries (before FILTER, before pre-alignment) by a small reusable `MERGE_BY_GROUP` subworkflow that concatenates each group's fastas and rebuilds one `meta` map. Global `skip_*` params are OR'd into every row so existing param-driven runs keep working. Samplesheets without the new columns behave byte-identically to today.

**Tech Stack:** Nextflow DSL2, Groovy (samplesheet parsing in `bin/utils.nf`), existing `CONCAT_FASTA_FILES` process, repo `test.nf` smoke-test convention.

## Global Constraints

- Nextflow strict mode is on (`nextflow.enable.strict = true`) — every declared workflow input must be provided; unused emits/takes error.
- Tuple convention is `[file, meta]` (file first, meta map second) everywhere except `CONCAT_FASTA_FILES`, whose input is `tuple(val(fasta_files), val(grouping_id))` and output is `tuple(path, val(grouping_id))`.
- Downstream output naming, the pipeline report, and multi-timepoint alignment key off `meta.sample_id`. After a group merge, `meta.sample_id` MUST equal the group id.
- New samplesheet columns (`group`, `skip_trim`, `skip_filter`) are OPTIONAL. Absent/blank → `group = sample_id`, `skip_trim = false`, `skip_filter = false`.
- Global override: effective `skip_trim = params.skip_trim OR row.skip_trim`; effective `skip_filter = params.skip_functional_filter OR row.skip_filter`.
- Tests follow the repo `test.nf` convention (runnable `nextflow run <path>/test.nf`). Pure-Groovy helpers use `assert` inside the test workflow for real pass/fail.

---

## File Structure

- `bin/utils.nf` — MODIFY. `parseSampleSheet` gains group fallback + boolean coercion; new `mergeGroupMeta(metas)` and `toBool(value)` helpers.
- `bin/test_utils.nf` — CREATE. Runnable `assert`-based test for the Groovy helpers.
- `modules/local/utils/concat_fasta/main.nf` — MODIFY. Drop the `CAP` filename prefix.
- `modules/local/utils/concat_fasta/test.nf` — MODIFY. Update to generalized naming / self-contained inputs.
- `subworkflows/local/merge_by_group/main.nf` — CREATE. Reusable group→concat→reattach-meta subworkflow with singleton short-circuit.
- `subworkflows/local/merge_by_group/test.nf` — CREATE. Smoke test with a 2-file group and a singleton.
- `workflows/preprocess/main.nf` — MODIFY. Per-file routing + two `MERGE_BY_GROUP` calls.
- `main.nf` — MODIFY. Fold global `skip_*` params into per-row effective flags when building `ch_input_files`.
- `nextflow_schema.json` — MODIFY (optional doc). No new params required; new columns are samplesheet-level.
- `test_data/samplesheet_grouped.csv` — CREATE. Exercises grouping + skips end-to-end.

---

## Task 1: Samplesheet parsing helpers in `bin/utils.nf`

**Files:**
- Modify: `bin/utils.nf`
- Test: `bin/test_utils.nf` (create)

**Interfaces:**
- Consumes: nothing (leaf).
- Produces:
  - `parseSampleSheet(samplesheet, sampleDir, otherMetadata)` → `List<[file, Map]>`; each `meta` now always has `group` (String), `skip_trim` (bool), `skip_filter` (bool), plus existing keys (`sample_id`, `filename`, `samplePath`, `num_seqs`, …).
  - `toBool(value)` → `boolean`; `null`/`""`/`"false"`/`"0"`/`"no"` (case-insensitive) → `false`; `"true"`/`"1"`/`"yes"` → `true`.
  - `mergeGroupMeta(List<Map> metas)` → `Map`; `sample_id` and `group` = `metas[0].group`; `num_seqs` = sum of members' `num_seqs`; every other key = first member's value (logs a warning when members disagree on that key).

- [ ] **Step 1: Write the failing test**

Create `bin/test_utils.nf`:

```nextflow
include { parseSampleSheet ; mergeGroupMeta ; toBool } from './utils'

workflow {
    // --- toBool ---
    assert toBool(null) == false
    assert toBool("") == false
    assert toBool("false") == false
    assert toBool("FALSE") == false
    assert toBool("0") == false
    assert toBool("no") == false
    assert toBool("true") == true
    assert toBool("TRUE") == true
    assert toBool("1") == true
    assert toBool("yes") == true

    // --- mergeGroupMeta ---
    def metas = [
        [sample_id: "m1", group: "G", num_seqs: 3, cap_name: "ABC", visit_id: "0"],
        [sample_id: "m2", group: "G", num_seqs: 2, cap_name: "ABC", visit_id: "0"],
    ]
    def merged = mergeGroupMeta(metas)
    assert merged.sample_id == "G"
    assert merged.group == "G"
    assert merged.num_seqs == 5
    assert merged.cap_name == "ABC"
    assert merged.visit_id == "0"

    // first-value-with-warn when members disagree (visit_id differs)
    def metas2 = [
        [sample_id: "m1", group: "G", num_seqs: 1, visit_id: "0"],
        [sample_id: "m2", group: "G", num_seqs: 1, visit_id: "1"],
    ]
    def merged2 = mergeGroupMeta(metas2)
    assert merged2.visit_id == "0"   // first wins

    // --- parseSampleSheet: group fallback + boolean coercion ---
    def sheet = file("${launchDir}/bin/test_data/mini_samplesheet.csv")
    def rows = parseSampleSheet(sheet, file("${launchDir}/test_data/inputs"), [:])
    def byId = rows.collectEntries { f, m -> [m.sample_id, m] }

    // row with no group column value → group defaults to sample_id
    assert byId["sampleA"].group == "sampleA"
    assert byId["sampleA"].skip_trim == false
    assert byId["sampleA"].skip_filter == false

    // row with explicit group + skips
    assert byId["sampleB"].group == "grp1"
    assert byId["sampleB"].skip_trim == true
    assert byId["sampleB"].skip_filter == false

    println "ALL bin/test_utils.nf ASSERTIONS PASSED"
}
```

Create the fixture `bin/test_data/mini_samplesheet.csv`:

```csv
sample_id,filename,group,skip_trim,skip_filter,cap_name,visit_id
sampleA,sample_a.fasta,,,,ABC,0
sampleB,sample_b.fasta,grp1,true,false,DEF,0
```

- [ ] **Step 2: Run test to verify it fails**

Run: `nextflow run bin/test_utils.nf`
Expected: FAIL — `No signature of method: ... mergeGroupMeta` / `toBool` (helpers not defined yet), or an assertion error on `group`/`skip_trim` because `parseSampleSheet` doesn't set them.

- [ ] **Step 3: Write minimal implementation**

Edit `bin/utils.nf` to this full content:

```nextflow
def toBool(value) {
    if (value == null) {
        return false
    }
    def s = value.toString().trim().toLowerCase()
    return s in ["true", "1", "yes"]
}

def mergeGroupMeta(metas) {
    def group = metas[0].group
    def merged = [:]

    // Start from the first member, take-first for every key.
    metas[0].each { k, v -> merged[k] = v }

    // Warn on disagreement for non-summed, non-identity keys.
    def skipKeys = ["num_seqs", "sample_id", "group"]
    metas[0].keySet().each { k ->
        if (k in skipKeys) {
            return
        }
        def distinct = metas.collect { it[k] }.unique()
        if (distinct.size() > 1) {
            log.warn("Group '${group}': members disagree on '${k}' (${distinct}); keeping first value '${merged[k]}'.")
        }
    }

    merged["sample_id"] = group
    merged["group"] = group
    merged["num_seqs"] = metas.sum { (it.num_seqs ?: 0) as int }
    return merged
}

def parseSampleSheet(samplesheet, sampleDir, otherMetadata) {
    def output_list = []

    samplesheet
        .splitCsv(header: true)
        .each { entry ->
            def new_output = []

            def filename = entry["filename"]
            def samplePath = sampleDir.resolve(filename)

            new_output.add(file(samplePath))
            entry = entry + otherMetadata
            entry["samplePath"] = file(samplePath)

            // Group defaults to sample_id when the column is absent or blank.
            def rawGroup = entry["group"]
            if (rawGroup == null || rawGroup.toString().trim() == "") {
                entry["group"] = entry["sample_id"]
            }
            else {
                entry["group"] = rawGroup.toString().trim()
            }

            // Coerce skip flags to booleans (absent/blank -> false).
            entry["skip_trim"] = toBool(entry["skip_trim"])
            entry["skip_filter"] = toBool(entry["skip_filter"])

            if (!entry.containsKey("num_seqs")) {
                def num_seqs = 0
                samplePath.eachLine { str ->
                    if (str.startsWith(">")) {
                        num_seqs += 1
                    }
                }

                entry["num_seqs"] = num_seqs
            }

            new_output.add(entry)

            output_list.add(new_output)
        }

    return output_list
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `nextflow run bin/test_utils.nf`
Expected: prints `ALL bin/test_utils.nf ASSERTIONS PASSED` and exits 0.

- [ ] **Step 5: Commit**

```bash
git add bin/utils.nf bin/test_utils.nf bin/test_data/mini_samplesheet.csv
git commit -m "✨ Add group fallback, skip-flag coercion, and mergeGroupMeta to samplesheet parsing"
```

---

## Task 2: Generalize `CONCAT_FASTA_FILES` filename

**Files:**
- Modify: `modules/local/utils/concat_fasta/main.nf`
- Test: `modules/local/utils/concat_fasta/test.nf`

**Interfaces:**
- Consumes: nothing new.
- Produces: `CONCAT_FASTA_FILES` still takes `tuple(val(fasta_files), val(grouping_id))` and emits `fasta_tuple = tuple(path("*.fasta"), val(grouping_id))`; output filename is now `${grouping_id}_merged.fasta` (no `CAP` prefix).

- [ ] **Step 1: Update the test to the generalized, self-contained form**

Replace `modules/local/utils/concat_fasta/test.nf` with:

```nextflow
include { CONCAT_FASTA_FILES } from "./main"

workflow {
    def file_a = file("${launchDir}/test_data/inputs/sample_a.fasta")
    def file_b = file("${launchDir}/test_data/inputs/sample_b.fasta")

    def input_ch = channel
        .from([[file_a, "grp1"], [file_b, "grp1"]])
        .map { f, g -> [g, f] }
        .groupTuple()
        .map { g, files -> [files, g] }

    CONCAT_FASTA_FILES(input_ch)

    CONCAT_FASTA_FILES.out.fasta_tuple.view { path, g ->
        assert path.name == "grp1_merged.fasta"
        "OK concat produced ${path.name} for group ${g}"
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `nextflow run modules/local/utils/concat_fasta/test.nf`
Expected: FAIL — assertion error, produced file is `CAPgrp1_merged.fasta`, not `grp1_merged.fasta`.

- [ ] **Step 3: Write minimal implementation**

Edit `modules/local/utils/concat_fasta/main.nf`:

```nextflow
process CONCAT_FASTA_FILES {
    input:
    tuple val(fasta_files), val(grouping_id)

    output:
    tuple path("*.fasta"), val(grouping_id), emit: fasta_tuple

    script:
    """
    cat ${fasta_files.join(' ')} > ${grouping_id}_merged.fasta
    """
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `nextflow run modules/local/utils/concat_fasta/test.nf`
Expected: prints `OK concat produced grp1_merged.fasta for group grp1`, exits 0.

- [ ] **Step 5: Commit**

```bash
git add modules/local/utils/concat_fasta/main.nf modules/local/utils/concat_fasta/test.nf
git commit -m "🔧 Generalize CONCAT_FASTA_FILES output name, drop vestigial CAP prefix"
```

---

## Task 3: `MERGE_BY_GROUP` subworkflow

**Files:**
- Create: `subworkflows/local/merge_by_group/main.nf`
- Create: `subworkflows/local/merge_by_group/test.nf`

**Interfaces:**
- Consumes: `CONCAT_FASTA_FILES` (Task 2), `mergeGroupMeta` (Task 1).
- Produces: `MERGE_BY_GROUP(sample_tuples)` where `sample_tuples` is a channel of `[file, meta]` (each `meta` has `group`). Emits `merged_tuples = [file, meta]`, one per distinct `group`. Groups of one file pass through unchanged (no concat, meta untouched). Groups of >1 are concatenated into a single fasta whose meta is `mergeGroupMeta(members)` (so `meta.sample_id == meta.group`, `num_seqs` summed).

- [ ] **Step 1: Write the failing test**

Create `subworkflows/local/merge_by_group/test.nf`:

```nextflow
include { MERGE_BY_GROUP } from "./main"

workflow {
    def file_a = file("${launchDir}/test_data/inputs/sample_a.fasta")
    def file_b = file("${launchDir}/test_data/inputs/sample_b.fasta")

    // grp1 has two members (should merge); solo has one (should pass through)
    def input_ch = channel.from([
        [file_a, [sample_id: "a1", group: "grp1", num_seqs: 2, cap_name: "ABC"]],
        [file_b, [sample_id: "b1", group: "grp1", num_seqs: 3, cap_name: "ABC"]],
        [file_a, [sample_id: "solo", group: "solo", num_seqs: 4, cap_name: "XYZ"]],
    ])

    MERGE_BY_GROUP(input_ch)

    MERGE_BY_GROUP.out.merged_tuples.view { f, m ->
        "MERGED group=${m.group} sample_id=${m.sample_id} num_seqs=${m.num_seqs} file=${f.name}"
    }

    // Assert: exactly 2 output tuples; grp1 merged to num_seqs=5 sample_id=grp1;
    // solo untouched sample_id=solo num_seqs=4.
    MERGE_BY_GROUP.out.merged_tuples
        .toList()
        .subscribe { rows ->
            assert rows.size() == 2
            def byGroup = rows.collectEntries { f, m -> [m.group, m] }
            assert byGroup["grp1"].sample_id == "grp1"
            assert byGroup["grp1"].num_seqs == 5
            assert byGroup["solo"].sample_id == "solo"
            assert byGroup["solo"].num_seqs == 4
            println "ALL merge_by_group ASSERTIONS PASSED"
        }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `nextflow run subworkflows/local/merge_by_group/test.nf`
Expected: FAIL — `MERGE_BY_GROUP` not found (module doesn't exist yet).

- [ ] **Step 3: Write minimal implementation**

Create `subworkflows/local/merge_by_group/main.nf`:

```nextflow
include { CONCAT_FASTA_FILES } from "../../../modules/local/utils/concat_fasta/main"
include { mergeGroupMeta } from "../../../bin/utils"

workflow MERGE_BY_GROUP {
    take:
    sample_tuples // channel of [file, meta]; meta has `group`

    main:
    // Collect each group's files and metas together.
    def grouped = sample_tuples
        .map { f, m -> [m.group, f, m] }
        .groupTuple()
        .branch { g, files, metas ->
            single: files.size() == 1
            multi: files.size() > 1
        }

    // Singletons pass straight through, untouched.
    def singles = grouped.single.map { g, files, metas -> [files[0], metas[0]] }

    // Multi-member groups: concatenate files, rebuild one meta.
    def to_concat = grouped.multi.map { g, files, metas -> [files, g] }
    CONCAT_FASTA_FILES(to_concat)

    def merged_meta = grouped.multi.map { g, files, metas -> [g, mergeGroupMeta(metas)] }

    def merged = CONCAT_FASTA_FILES.out.fasta_tuple
        .map { path, g -> [g, path] }
        .join(merged_meta)
        .map { g, path, meta -> [path, meta] }

    emit:
    merged_tuples = singles.mix(merged)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `nextflow run subworkflows/local/merge_by_group/test.nf`
Expected: two `MERGED ...` lines and `ALL merge_by_group ASSERTIONS PASSED`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add subworkflows/local/merge_by_group/main.nf subworkflows/local/merge_by_group/test.nf
git commit -m "✨ Add MERGE_BY_GROUP subworkflow for group-wise fasta merging"
```

---

## Task 4: Per-file routing inside `PREPROCESS`

**Files:**
- Modify: `workflows/preprocess/main.nf`

**Interfaces:**
- Consumes: `MERGE_BY_GROUP` (Task 3). Each incoming `[file, meta]` has `meta.skip_trim` and `meta.skip_filter` (booleans, already OR'd with globals by Task 5). `meta.group` is present.
- Produces: same emits as today (`sample_tuples_aa`, `sample_tuples_nt`, `namefile_tuples`, `sample_tuples_rejected_nt`, `filter_report`, `sample_tuples_length_trimmed_nt`). The `skip_trim` / `skip_functional_filter` scalar `take:` inputs are REMOVED (routing is now per-file via meta). `functional_filter_method`, `use_kmer_filtering`, `trim_method`, `trim_coords`, `ch_reference_file`, `ch_refToAdd`, `add_ref_before_align` stay.

- [ ] **Step 1: Replace `workflows/preprocess/main.nf`**

Full new content:

```nextflow
include { TRIM_AGA } from "../../subworkflows/local/trim_aga/main"
include { TRIM_MINIMAP } from "../../subworkflows/local/trim_minimap/main"
include { LENGTH_BASED_FILTERING } from "../../subworkflows/local/length_based_filtering/main"
include { PRE_ALIGNMENT_PROCESSING } from "../../subworkflows/local/pre_alignment_process/main"
include { MERGE_BY_GROUP as MERGE_BEFORE_FILTER } from "../../subworkflows/local/merge_by_group/main"
include { MERGE_BY_GROUP as MERGE_BEFORE_ALIGN } from "../../subworkflows/local/merge_by_group/main"
include { FUNCTIONAL_FILTER } from "../../modules/local/functional_filter/main"

workflow PREPROCESS {
    take:
    ch_input_files
    ch_reference_file
    trim_method
    ch_refToAdd
    add_ref_before_align
    functional_filter_method
    use_kmer_filtering
    trim_coords

    main:
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // SEQUENCE TRIMMING (per-file: rows with skip_trim bypass)
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def to_trim = ch_input_files.filter { f, m -> !m.skip_trim }
    def bypass_trim = ch_input_files.filter { f, m -> m.skip_trim }

    def ch_trimmed
    if (trim_method == "AGA") {
        TRIM_AGA(to_trim, ch_reference_file)
        ch_trimmed = TRIM_AGA.out.preprocessed_nt_seqs
    }
    else if (trim_method == "MINIMAP2") {
        TRIM_MINIMAP(to_trim, ch_reference_file, trim_coords)
        ch_trimmed = TRIM_MINIMAP.out.preprocessed_nt_seqs
    }
    else {
        error("Preprocessing type not recognized: ${trim_method}")
    }

    def ch_after_trim = ch_trimmed.mix(bypass_trim)

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // FUNCTIONAL FILTERING (per-file: rows with skip_filter bypass)
    // Members that need filtering are merged per group first, so the filter
    // sees the whole group together (consistent length median).
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def to_filter = ch_after_trim.filter { f, m -> !m.skip_filter }
    def bypass_filter = ch_after_trim.filter { f, m -> m.skip_filter }

    MERGE_BEFORE_FILTER(to_filter)
    def ch_to_filter_merged = MERGE_BEFORE_FILTER.out.merged_tuples

    def ch_functional_filter_out
    def ch_ff_report
    def ch_ff_rejected
    def ch_ff_trimmed_to_stop
    if (functional_filter_method == "ELLPACA") {
        FUNCTIONAL_FILTER(ch_to_filter_merged)
        ch_functional_filter_out = FUNCTIONAL_FILTER.out.filtered_tuples
        ch_ff_report = FUNCTIONAL_FILTER.out.report
        ch_ff_rejected = FUNCTIONAL_FILTER.out.rejected_records
        ch_ff_trimmed_to_stop = channel.empty()
    }
    else if (functional_filter_method == "LENGTH_BASED_FILTERING") {
        LENGTH_BASED_FILTERING(ch_to_filter_merged, use_kmer_filtering)
        ch_functional_filter_out = LENGTH_BASED_FILTERING.out.length_filtered_tuples
        ch_ff_report = LENGTH_BASED_FILTERING.out.length_filter_report
        ch_ff_rejected = LENGTH_BASED_FILTERING.out.length_rejected_records
        ch_ff_trimmed_to_stop = LENGTH_BASED_FILTERING.out.trimmed_to_stop_nt
    }
    else {
        error("Functional filter method not recognized: ${functional_filter_method}")
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // MERGE BEFORE ALIGNMENT: filtered group fastas + skip-filter members,
    // reunited per group into a single fasta.
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MERGE_BEFORE_ALIGN(ch_functional_filter_out.mix(bypass_filter))
    def ch_pre_alignment_input = MERGE_BEFORE_ALIGN.out.merged_tuples

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // TRANSLATE - COLLAPSE - ADD REF (OPTIONAL)
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRE_ALIGNMENT_PROCESSING(
        ch_pre_alignment_input,
        add_ref_before_align,
        ch_refToAdd,
    )

    emit:
    sample_tuples_aa = PRE_ALIGNMENT_PROCESSING.out.sample_tuples_aa
    sample_tuples_nt = PRE_ALIGNMENT_PROCESSING.out.sample_tuples_nt
    namefile_tuples = PRE_ALIGNMENT_PROCESSING.out.namefile_tuples
    sample_tuples_rejected_nt = ch_ff_rejected
    filter_report = ch_ff_report
    sample_tuples_length_trimmed_nt = ch_ff_trimmed_to_stop
}
```

> Note: this also fixes the pre-existing emit-name mismatch — the old code referenced `LENGTH_BASED_FILTERING.out.filtered_tuples`/`.report`/`.rejected_records`, but the subworkflow actually emits `length_filtered_tuples`/`length_filter_report`/`length_rejected_records`. The new code uses the correct names.

- [ ] **Step 2: Confirm it parses / no strict-mode take mismatch yet**

Run: `nextflow run main.nf -profile test --help` is not applicable; instead do a config-only parse check:
Run: `nextflow inspect main.nf -profile test 2>&1 | head -20` (or `nextflow run main.nf -profile test -preview` if available).
Expected: at this point `main.nf` still calls `PREPROCESS(...)` with the old argument list, so you WILL see an arity/strict error about `PREPROCESS`. That is expected and is fixed in Task 5. Proceed.

- [ ] **Step 3: Commit (paired with Task 5 for a runnable state)**

```bash
git add workflows/preprocess/main.nf
git commit -m "♻️ Route trimming and filtering per-file with group merges in PREPROCESS"
```

---

## Task 5: Fold global params into per-row flags and update `PREPROCESS` call in `main.nf`

**Files:**
- Modify: `main.nf`

**Interfaces:**
- Consumes: `parseSampleSheet` (Task 1) output; `PREPROCESS` new signature (Task 4).
- Produces: `ch_input_files` where each `meta.skip_trim` / `meta.skip_filter` is `row_flag OR global_param`. `MAIN_WORKFLOW`'s `skip_trim` / `skip_functional_filter` params are still used for the `PIPELINE_REPORT` gate but no longer passed into `PREPROCESS`.

- [ ] **Step 1: Fold globals when building the input channel**

In `main.nf`, replace the current channel construction (around line 314):

```nextflow
    ch_input_files = channel.fromList(sample_tuples)
```

with:

```nextflow
    ch_input_files = channel.fromList(sample_tuples).map { f, meta ->
        def eff = meta + [
            skip_trim: (meta.skip_trim ?: false) || params.skip_trim,
            skip_filter: (meta.skip_filter ?: false) || params.skip_functional_filter,
        ]
        [f, eff]
    }
```

- [ ] **Step 2: Update the `PREPROCESS` call inside `MAIN_WORKFLOW`**

Replace the existing `PREPROCESS(...)` invocation (lines 68-79) with the new argument list (drops `skip_trim`, `skip_functional_filter`):

```nextflow
    PREPROCESS(
        ch_input_files,
        ch_reference_file,
        trim_method,
        ch_refToAdd,
        add_ref_before_align,
        functional_filter_method,
        use_kmer_filtering,
        trim_coords,
    )
```

Leave the `skip_trim` and `skip_functional_filter` entries in `MAIN_WORKFLOW`'s `take:` block and the top-level `MAIN_WORKFLOW(...)` call intact — they still gate `PIPELINE_REPORT` at line ~126. Only their use as `PREPROCESS` arguments is removed.

- [ ] **Step 3: Run the existing (ungrouped) test end-to-end**

Run: `nextflow run -c nextflow.config main.nf -profile test --samplesheet test_data/samplesheet.csv --sample_base_dir test_data/inputs --reference_file <existing test reference> --region_of_interest <existing test region>`

(Use the exact invocation from `docs/usage.md` / `README.md` line 44 for the test profile — copy its `--reference_file`, `--region_of_interest`, and any `--trim_method`/`--aligner` flags verbatim.)

Expected: pipeline completes; `results/` contains the same `nucleotide_alignments/` and `amino_acid_alignments/` outputs as before this change (two samples: `sampleA`, `sampleB`). No group merging occurs because the default samplesheet has no `group` column.

- [ ] **Step 4: Commit**

```bash
git add main.nf
git commit -m "🔧 OR global skip params into per-row flags; update PREPROCESS call"
```

---

## Task 6: End-to-end grouped run + samplesheet fixture + docs

**Files:**
- Create: `test_data/samplesheet_grouped.csv`
- Modify: `docs/usage.md` (document the new columns)

**Interfaces:**
- Consumes: the full pipeline (Tasks 1-5).
- Produces: a demonstration samplesheet and user-facing docs. No code interface.

- [ ] **Step 1: Create the grouped fixture**

Create `test_data/samplesheet_grouped.csv` (both files land in one group `grp1`; `sample_b` is pre-trimmed so it skips trim and rejoins before filtering):

```csv
sample_id,filename,group,skip_trim,skip_filter,cap_name,visit_id,sequencing_pool
sampleA,sample_a.fasta,grp1,false,false,ABC,0,
sampleB,sample_b.fasta,grp1,true,false,DEF,0,
```

- [ ] **Step 2: Run the grouped pipeline end-to-end**

Run the same invocation as Task 5 Step 3 but with `--samplesheet test_data/samplesheet_grouped.csv`.

Expected:
- `sampleA` is trimmed; `sampleB` bypasses trim.
- A single merged fasta per `grp1` enters filtering (one median across both files).
- One alignment is produced named by the group: `nucleotide_alignments/grp1_aligned_nt.fasta` and `amino_acid_alignments/grp1_aligned_aa.fasta` (because merged `meta.sample_id == "grp1"`).
- The run log shows exactly one TRIM invocation (for `sampleA`) and one filter invocation (for the merged `grp1`).

Verify:
Run: `ls results/nucleotide_alignments/`
Expected: contains `grp1_aligned_nt.fasta` (and no separate `sampleA`/`sampleB` alignments).

- [ ] **Step 3: Document the new columns in `docs/usage.md`**

Add a section describing the optional samplesheet columns:

```markdown
### Optional samplesheet columns for per-file step skipping

| Column        | Default       | Meaning                                                      |
|---------------|---------------|--------------------------------------------------------------|
| `group`       | `sample_id`   | Files sharing a `group` are merged into a single alignment.  |
| `skip_trim`   | `false`       | This file bypasses trimming (already trimmed).               |
| `skip_filter` | `false`       | This file bypasses functional filtering (already filtered).  |

Files that skip a step are merged back with their group's other files before
the next non-skipped step: skip-trim files rejoin before filtering, skip-filter
files rejoin before alignment. The global `--skip_trim` / `--skip_functional_filter`
params force the corresponding skip for **all** files, on top of per-row flags.
```

- [ ] **Step 4: Commit**

```bash
git add test_data/samplesheet_grouped.csv docs/usage.md
git commit -m "📝 Add grouped samplesheet fixture and document per-file skip columns"
```

---

## Self-Review

**Spec coverage:**
- Samplesheet schema (`group`/`skip_trim`/`skip_filter`, optional, defaults) → Task 1 (parse) + Task 6 (fixture/docs) + Task 5 (global OR). ✓
- Parsing & merged metadata (`mergeGroupMeta`, `sample_id=group`, summed `num_seqs`, first-value+warn) → Task 1. ✓
- Global-param force-all override → Task 5. ✓
- PREPROCESS refactor with per-file routing + progressive merges A & B, trim per-file → Task 4. ✓
- Singleton short-circuit / byte-identical ungrouped behavior → Task 3 (`MERGE_BY_GROUP` single branch) + Task 5 Step 3 (regression run). ✓
- `CONCAT_FASTA_FILES` generalize filename → Task 2. ✓
- Worked ELLPACA example (trim one, skip-trim another, filter together, align once) → Task 6 fixture/run. ✓
- Testing (parseSampleSheet, mergeGroupMeta, PREPROCESS group behavior, backward-compat) → Tasks 1, 3, 5, 6. ✓

**Placeholder scan:** No TBD/TODO/"handle edge cases"; every code step has full code. The only bracketed placeholders are the concrete `--reference_file`/`--region_of_interest` values in Tasks 5-6, which must be copied verbatim from `README.md`/`docs/usage.md` (repo-specific, not inventable here). ✓

**Type consistency:** `mergeGroupMeta(metas)` signature identical in Tasks 1 and 3. `MERGE_BY_GROUP` emits `merged_tuples = [file, meta]` in Tasks 3 and 4. `CONCAT_FASTA_FILES.out.fasta_tuple = [path, grouping_id]` used consistently in Tasks 2 and 3. `LENGTH_BASED_FILTERING` emit names (`length_filtered_tuples`, `length_filter_report`, `length_rejected_records`, `trimmed_to_stop_nt`) match the actual subworkflow. ✓
