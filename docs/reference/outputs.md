---
icon: lucide/folder-tree
---

# Output Reference

The top-level output directory tree is given in [Running the CLI](../user-guide/running-cli.md#outputs).
This page describes the contents of each directory in more detail, along with the naming
convention used for the files within it.

## `preprocess/trimmed_sequences/`

This directory is produced unless `--skip_trim` is set. It contains the trimmed coding
region for each sample, output by whichever preprocessing method was selected (`MINIMAP2`
or `AGA`; see [Stage 1 — Preprocessing](../index.md#stage-1-preprocessing-trim)), one FASTA
file per sample:

```
<sample_id>_trimmed_nt.fasta
```

## `functional_filter/`

This directory holds the output of the functional filtering stage (see [Stage 2 —
Functional Filtering](../index.md#stage-2-functional-filtering) for what "functional"
means in this context), and its contents depend on the `functional_filter_method` in use:

- **`reports/`** — for each sample, a CSV summarizing filter activity:
  `<sample_id>_filter-report.csv`.
- **`rejected_sequences/`** — the sequences that failed the filter, one FASTA per sample:
  `<sample_id>_filter-rejected.fasta`.
- **`passed_sequences/`** — the sequences that passed and were carried forward to
  alignment: `<sample_id>_filter-passed.fasta`.
- **`trim_stop/`** — produced only when `functional_filter_method` is
  `LENGTH_BASED_FILTERING`. Contains sequences trimmed to their first stop codon, prior to
  length or k-mer filtering: `<sample_id>_trimmed_to_stop.fasta`.

`LENGTH_BASED_FILTERING` is itself applied in up to two stages: length filtering, followed
by an optional k-mer filtering stage when `use_kmer_filtering` is set. Where both stages
run, `reports/` and `rejected_sequences/` each gain a `length/` and `kmer/` subdirectory,
and the corresponding filenames are given a stage suffix, e.g.
`<sample_id>_length-filter-report.csv` and `<sample_id>_kmer-filter-rejected.fasta`. Under
`ELLPACA`, the default method, filtering runs as a single stage, and its reports and
rejected sequences are written directly into `reports/` and `rejected_sequences/` without a
stage subdirectory.

## `alignments/`

Alignment output is split by sequence type:

- **`nucleotide_alignments/`** — the codon-aware nucleotide MSA for each sample:
  `<sample_id>_aligned_nt.fasta`.
- **`amino_acid_alignments/`** — the corresponding amino acid MSA:
  `<sample_id>_aligned_aa.fasta`.
- **`profile_alignments/`** — produced only by the `multi_timepoint_alignment` workflow,
  which is deprecated and should not be relied upon in new runs.

All alignment files are gap-padded FASTA (`-` as the gap character), with one record per
input sequence plus the reference sequence used to anchor the alignment.

## `phylogeny/`

Produced only when `--build_phylogeny` is set:

- **`trees/`** — the inferred tree for each sample, in Newick format:
  `<sample_id>_<alignment_type>.tree`, where `<alignment_type>` is `NT` or `AA` according
  to `phylogeny_alignment_type`.
- **`iqtree_files/`** — IQ-TREE's remaining run artifacts alongside the tree file (log
  file, model selection report, and so on), useful for inspecting how a tree was built or
  diagnosing a failed run.

A per-site variation heatmap keyed off `phylogeny_baseline_method` is planned but not yet
implemented, so no heatmap files are produced regardless of that parameter's value.

## `execution_report/`

A generated run report recording the git commit, run parameters, and plots of sequence
attrition through the pipeline. This module is legacy and is being removed in an
upcoming release, so its contents should not be depended on by external tooling.

## `logs/`

This directory contains the per-process log files for every task executed by the
pipeline, organized as `logs/<PROCESS_NAME>/<tag>/`, where `<tag>` is the task's Nextflow
tag (typically the sample ID). Each task's `.command.*` files are copied in under a `.txt`
extension:

- **`command.sh.txt`** — the script that was actually executed for the task.
- **`command.out.txt`** — the task's captured stdout.
- **`command.err.txt`** — the task's captured stderr.
- **`command.log.txt`** — stdout and stderr combined, in the order Nextflow received them.

This makes it possible to inspect a specific failed or misbehaving task without searching
through Nextflow's `work/` directory.

## `pipeline_info/`

Nextflow's built-in run reporting is generated for every run and written here:

- **`execution_report_<run_name>_<timestamp>.html`** — per-process resource usage
  (CPU, memory, time), useful for spotting which stage of a run is the bottleneck.
- **`execution_timeline_<run_name>_<timestamp>.html`** — a Gantt-style timeline of task
  execution, showing where tasks ran in parallel and where they queued.
- **`execution_trace_<run_name>_<timestamp>.txt`** — a tab-separated trace of every task,
  including status, timing, and resource usage; useful for scripted post-run analysis.
- **`pipeline_dag_<run_name>_<timestamp>.html`** — the resolved pipeline DAG.
