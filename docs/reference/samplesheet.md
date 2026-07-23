---
icon: lucide/table
---

# Samplesheet Reference

The samplesheet is a CSV passed via `samplesheet`, resolved against `sample_base_dir`.

## Required columns

| Column | Meaning |
|---|---|
| `sample_id` | Unique identifier for the sample. |
| `filename` | Path to the input FASTA file, resolved relative to `sample_base_dir`. |

## Optional columns

| Column | Default | Meaning |
|---|---|---|
| `group` | `sample_id` | Files sharing a `group` are merged into a single alignment. |
| `skip_trim` | `false` | Skip trimming for this file (already trimmed). |
| `skip_filter` | `false` | Skip functional filtering for this file (already filtered). |

Files that skip a step rejoin their group before the next non-skipped step:
skip-trim files rejoin before filtering, skip-filter files rejoin before alignment.
The global `skip_trim` / `skip_functional_filter` params force the corresponding
skip for all files, on top of any per-row flags.

See `sample_data/samplesheet_grouped.csv` for an example that merges two files
into one alignment.

## Extra columns

Any other column is carried through as per-sample metadata (e.g. `cap_name`,
`visit_id`) and is not interpreted by the pipeline itself — use it for
whatever bookkeeping you need downstream.
