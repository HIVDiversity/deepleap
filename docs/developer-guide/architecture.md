---
icon: lucide/network
---

# Pipeline Architecture

DeepLEAP is implemented as a Nextflow pipeline, organized as a small hierarchy of
named workflows rather than as one monolithic script. This page describes how those
layers fit together and the reasoning behind the main implementation decisions.

## High-level structure

The pipeline is assembled in four layers:

- **`main.nf`** — the entry point. It validates parameters, resolves the reference
  sequence and samplesheet into Nextflow channels, and calls `MAIN_WORKFLOW`, which
  orchestrates the pipeline's stages in order.
- **`workflows/`** — the named, top-level stages: `PREPROCESS`, `ALIGN`, `POSTPROCESS`,
  `PHYLOGENY`, and `MULTI_TIMEPOINT_ALIGNMENT` (deprecated). `MAIN_WORKFLOW` calls these
  in sequence, threading the sample tuples produced by one stage into the next.
  `MAIN_WORKFLOW` also owns two pieces of orchestration that don't belong in any single
  stage: dispatching to `PIPELINE_REPORT` once alignment has finished, and deciding
  whether nucleotide or amino acid output feeds `PHYLOGENY`, based on
  `phylogeny_alignment_type`.
- **`subworkflows/`** — reusable logic shared across workflows, such as
  `MERGE_BY_GROUP` (used identically before filtering and before alignment) or
  `TRIM_MINIMAP` / `TRIM_AGA` (the two implementations of the `PREPROCESS` workflow's
  trimming step).
- **`modules/local/`** — the atomic units: one process per external tool invocation
  (`mafft`, `minimap2`, `iqtree`, and so on) or per custom operation. See [Pipeline
  Modules](pipeline-modules.md) for the full catalogue.

Sample data flows through these layers as Nextflow tuples of `(file, meta)`, where
`meta` is a per-sample metadata map built from the samplesheet (`sample_id`, `group`,
`skip_trim`, `skip_filter`, and any extra columns) plus a handful of pipeline-level
additions, such as `region_of_interest` and `ref_seq_name`.

## Stage 1 — Preprocessing (Trim)

Implemented by the `PREPROCESS` workflow, which selects one of two subworkflows
according to `trim_method`:

- **`TRIM_MINIMAP`** — maps each sample to the reference with `minimap2`, then trims
  the mapped read to fixed coordinates with `pipeline-utils-rs trim-sam`. This is the
  default and faster of the two, but assumes a single, non-overlapping reading frame.
- **`TRIM_AGA`** — delegates directly to AGA, which can resolve multiple overlapping
  reading frames at the cost of speed.

Rows with `skip_trim` set (per-row in the samplesheet, or globally via
`--skip_trim`) bypass this stage entirely and rejoin the trimmed samples before
functional filtering.


## Stage 2 — Functional Filtering

Also implemented within the `PREPROCESS` workflow, after trimmed samples are merged
by group (see below). The method used is selected by `functional_filter_method`:

- **`ELLPACA`** (default) — a single call to `functional_filter`, which applies the
  stop-codon criteria agreed on by the ellpaca group (see
  [Parameters](../reference/parameters.md) for the specific thresholds).
- **`LENGTH_BASED_FILTERING`** — the `LENGTH_BASED_FILTERING` subworkflow: trim-to-stop,
  then length filtering, then an optional k-mer filtering pass.

As with trimming, rows with `skip_filter` set bypass this stage and rejoin the
filtered samples before alignment. See the [Output Reference](../reference/outputs.md#functional_filter)
for what each method writes to `functional_filter/`.

## Stage 3 — Alignment

Implemented by the `ALIGN` workflow, which dispatches on the `aligner` parameter to
one of the per-tool modules cataloged in [Pipeline Modules](pipeline-modules.md)
(`mafft`, `muscle`, `macse`, `virulign`, `pagan`, `probcons`, `tcoffee`, `prank`,
`clustal`). Most aligners operate on translated amino acid sequences; `MACSE` and
`VIRULIGN` are the exceptions, since they align nucleotide sequences directly
(`is_nt_aligner` in `main.nf` routes the correct sequence type to `ALIGN`
accordingly).

Where alignment happens on amino acids, the `POSTPROCESS` workflow performs the
"backtranslation" mentioned in the [pipeline overview](../index.md#stage-3-alignment):
it expands collapsed duplicate sequences back out, then uses the amino acid
alignment's gap pattern to reconstruct a matching nucleotide alignment
(`REVERSE_TRANSLATE`). A reference sequence can optionally be added to the sequences
being aligned, either before alignment (`add_reference_to_sequences: BEFORE`, folded
into the aligner's own input) or after (`AFTER`, added via `MAFFT_ADD` once the rest
of the alignment already exists).

## Sample grouping & merging

Samples that share a `group` value in the samplesheet (see the [Samplesheet
Reference](../reference/samplesheet.md)) are concatenated into a single file by the
`MERGE_BY_GROUP` subworkflow before being handed to a stage that needs to see the
whole group at once — first before functional filtering, so that filtering
criteria are evaluated consistently across a group rather than per-file, and again
before alignment, so that a group's sequences end up in one alignment rather than
several. Groups of size one pass through unchanged.

## Reporting

Two independent reporting mechanisms run alongside the pipeline:

- **`pipeline_info/`** — Nextflow's own built-in execution report, timeline, trace,
  and DAG, generated for every run regardless of pipeline parameters.
- **`PIPELINE_REPORT`** — a custom module that summarizes sequence attrition and
  alignment output across a run (git commit, parameters, an UpSet plot of rejected
  sequences, sequence count/length plots, and an MSA overview). This module is
  legacy and being removed in an upcoming release.

Both are described file-by-file in the [Output Reference](../reference/outputs.md).

## Design rationale

Nextflow was chosen as the pipeline's DSL primarily for its execution-environment
abstraction: the same pipeline runs unmodified on a laptop, an HPC cluster, or a
cloud provider, with clear execution reporting and configuration support included
for free. Its drawbacks — a steep learning curve, obscure runtime errors stemming
from its Groovy foundation, and no formal type system — were judged an acceptable
tradeoff given its active maintenance and wide adoption.

Every module is containerized, with custom Docker images used in preference to
third-party ones wherever practical. This was done for portability across execution
environments (the same Dockerfile-based images run under Docker, Singularity, and
Apptainer) and to pin exact tool versions rather than depend on whatever happens to
be installed on the host. The tradeoff is a dependency on container registries for
image availability, and a debugging experience that is one level more indirect than
running tools directly on the host.
