# Design: Per-file step skipping with group merging

**Date:** 2026-07-08
**Status:** Approved (pending spec review)

## Problem

Today the pipeline treats every samplesheet row as an independent sample: one file
→ one `[file, meta]` tuple → one alignment. Trimming and functional filtering are
controlled by *global* params (`skip_trim`, `skip_functional_filter`), so skipping a
step is all-or-nothing across every input file.

We need per-file control: some input files must be trimmed and/or filtered, while
others are already trimmed/filtered and should bypass those steps. Critically, files
that skip a step still belong to the same logical sample and must be **merged back
with their sister files** and end up in a single alignment.

The concrete driver (from `llm_plans/20260708_PlannedAddititons.md`, item 3 / the
ELLPACA case): ELLPACA sequences are trimmed; LANL sequences are already trimmed and
are added to the trimmed ELLPACA set; the combined set is then filtered together
(start codon / stop codon / length) and aligned.

The only steps meaningful to skip are **trimming** and **functional filtering**.

## Pipeline context

Stage chain in `workflows/preprocess/main.nf`:

```
trim → functional filter → pre-alignment (translate/collapse/add-ref) → align
```

- Trimming (AGA / MINIMAP2) operates per sequence, independent of other sequences.
- Functional filtering — specifically `LENGTH_BASED_FILTERING` — computes a **median
  length per input file**, so which sequences share a file at filter time changes the
  result. Grouping must therefore be reunited *before* filtering, not just before
  alignment.
- Downstream output naming (`main.nf` `output` block), the pipeline report, and
  multi-timepoint alignment all key off `meta.sample_id`.

## Decisions (from brainstorming)

1. **Dedicated `group` column** — not overloading `sample_id`. `sample_id` stays unique
   per physical file; rows sharing a `group` value merge into one alignment.
2. **Progressive merge** at each stage boundary (not a single merge before alignment),
   so filtering sees the whole group together (one consistent median).
3. **Two boolean columns** `skip_trim` and `skip_filter` (not one token column).
4. **Merged meta** = group identity + summed `num_seqs`; for every other column, take
   the first member's value (warn when members actually differ).
5. **Global params force-all**: a global `skip_trim` / `skip_functional_filter` forces
   that skip for *all* rows, OR'd with each row's per-file flag.
6. **Generalize `CONCAT_FASTA_FILES` filename** — drop the vestigial `CAP` prefix.

## Samplesheet schema

Three new **optional** columns. Existing samplesheets (without them) behave exactly as
today — each row is its own group of one and skips nothing.

| Column        | Type   | Default (blank →)   | Meaning                                             |
|---------------|--------|---------------------|-----------------------------------------------------|
| `group`       | string | `sample_id`         | Merge unit; rows sharing a value → one alignment     |
| `skip_trim`   | bool   | `false`             | This file bypasses trimming                          |
| `skip_filter` | bool   | `false`             | This file bypasses functional filtering              |

## Components

### 1. Samplesheet parsing — `bin/utils.nf`

`parseSampleSheet` changes:
- `group ← sample_id` when the column is absent or blank.
- Coerce `skip_trim` / `skip_filter` to booleans (blank / absent → `false`;
  accept `true`/`false` case-insensitively).
- No merging happens in the parser — it still emits one entry per physical file.

New helper `mergeGroupMeta(members)` (in `bin/utils.nf`), applied in the workflow when a
group of member `meta` maps collapses into one:
- `sample_id = group`, `group = group`
- `num_seqs = sum(members.num_seqs)`
- every other key: take the first member's value; `log.warn` if members disagree on that key
- Because merged `sample_id == group`, all downstream naming/reporting keeps working
  with no changes. Singleton, ungrouped rows are byte-identical to today.

### 2. Global-param override — `main.nf`

Before entering `PREPROCESS`, fold the global params into each row's flags:
- `effective skip_trim   = global skip_trim   OR row.skip_trim`
- `effective skip_filter = global skip_functional_filter OR row.skip_filter`

This preserves existing param-driven runs (global skip → every row skips).

### 3. PREPROCESS refactor — `workflows/preprocess/main.nf`

Replace the linear chain with group-keyed routed channels:

```
ch_input ──┬─ !skip_trim ─► TRIM ─┐
           └─ skip_trim ──────────┴─► ch_after_trim
                                        ├─ !skip_filter ─► [merge A by group] ─► FILTER ─┐
                                        └─ skip_filter ──────────────────────┐          │
                                                                             ▼          ▼
                                          [merge B by group: filtered + skip_filter] ─► PRE_ALIGNMENT ─► ALIGN
```

- **Trim stage:** partition `ch_input` on effective `skip_trim`. Trim-needing files go
  through `TRIM_AGA` / `TRIM_MINIMAP` as today; skip-trim files bypass. Mix back into
  `ch_after_trim`. Trim stays per-file (no pre-merge).
- **Merge A (before FILTER):** take `ch_after_trim` members with `!skip_filter`, group by
  `meta.group`, `CONCAT_FASTA` per group, attach `mergeGroupMeta`. One median per group.
- **FILTER stage:** unchanged internally (`ELLPACA` or `LENGTH_BASED_FILTERING`), now
  operating on one merged fasta per group.
- **Merge B (before pre-alignment):** mix FILTER output (per-group) with the
  `skip_filter` members, group by `meta.group`, `CONCAT_FASTA`, attach `mergeGroupMeta`.
- **Singleton short-circuit:** at each merge point, a group with exactly one file skips
  `CONCAT_FASTA` and passes the file through unchanged — avoids a needless process and
  keeps ungrouped runs identical to today.

### 4. `CONCAT_FASTA_FILES` — `modules/local/utils/concat_fasta/main.nf`

Generalize the output filename from `CAP${grouping_id}_merged.fasta` to
`${grouping_id}_merged.fasta`. No interface change otherwise.

## Data flow — worked example (ELLPACA)

Group `G` has three files:
- `ellpaca` — `skip_trim=false`, `skip_filter=false`
- `lanl`    — `skip_trim=true`,  `skip_filter=false`
- `extra`   — `skip_trim=true`,  `skip_filter=true`

Flow:
1. `ellpaca` → TRIM. `lanl`, `extra` bypass.
2. Merge A: `{trimmed ellpaca, lanl}` (both `!skip_filter`) → one fasta → FILTER (one median).
3. Merge B: `{filtered(ellpaca+lanl), extra}` → one fasta → PRE_ALIGNMENT → ALIGN.
4. Single aligned output named by `meta.sample_id == "G"`, `num_seqs` = sum of members.

## Edge cases

- File skipping **both** steps flows straight to Merge B.
- A group whose filter rejects everything: existing filter behavior handles empty
  outputs; the singleton/empty guard avoids merging an empty set.
- Members of a group disagree on a non-group column (e.g. `cap_name`): take first, `log.warn`.
- Fully backward compatible: a samplesheet without the new columns → every row is a
  singleton group skipping nothing → unchanged behavior.

## Testing

- Unit: `parseSampleSheet` — `group` fallback to `sample_id`, boolean coercion of
  `skip_trim`/`skip_filter`, blanks default to false.
- Unit: `mergeGroupMeta` — summed `num_seqs`, `sample_id == group`, first-value-with-warn.
- Subworkflow: PREPROCESS with the 3-file ELLPACA group above — assert a single merged
  alignment input with summed `num_seqs`, and that filtering ran once on the merged set.
- Backward-compat: existing samplesheet → outputs unchanged.
- Global-override: global `skip_trim` on + per-row flags → every row skips trim.

## Out of scope

- Skipping any step other than trim and filter.
- Adding sequences at arbitrary/other stage boundaries beyond trim and filter.
- Changes to alignment, postprocessing, phylogeny, or output-naming logic.
