---
icon: lucide/puzzle
---

# Pipeline Modules

The DeepLEAP pipeline is modular, and depends on a mixture of pre-existing bioinformatics
tools and custom-written ones. This page gives a one-line description of each module and
subworkflow under `modules/local/` and `subworkflows/local/`, as a companion to reading
the code itself.

## Modules (`modules/local/`)

| Module | Description |
|---|---|
| `aga` | Wraps AGA, an alternative to `minimap2` for trimming sequences with complex or overlapping reading frame structures during preprocessing. |
| `clustal` | Runs Clustal Omega and ClustalW, two of the alignment tools evaluated in the [aligner benchmark](../reference/aligners.md). |
| `collapse_expand_fasta` | Collapses duplicate sequences into a single representative before alignment, and expands them back afterwards, to avoid paying alignment cost for identical sequences. |
| `draw_tree_heatmap` | Renders a per-site variation heatmap alongside a phylogenetic tree. Not currently wired into the pipeline — see the [Output Reference](../reference/outputs.md#phylogeny). |
| `functional_filter` | Runs `functional-filter`, the ELLPACA-criteria functional filtering tool, over trimmed sequences and reports which are retained. |
| `iqtree` | Runs IQ-TREE to infer a phylogenetic tree from a computed alignment, when `build_phylogeny` is enabled. |
| `macse` | Runs MACSE, one of the alignment tools evaluated in the aligner benchmark. |
| `mafft` | Runs MAFFT in its various modes: standard alignment, fast alignment, adding a reference sequence, seeding against a profile alignment, and merging pre-split alignments back together. |
| `minimap2` | Maps input reads to the reference sequence, as the default preprocessing method for extracting the region of interest. |
| `muscle` | Runs MUSCLE, one of the alignment tools evaluated in the aligner benchmark, including its faster Super5 mode. |
| `pagan` | Runs PAGAN, a phylogeny-aware alignment tool. |
| `pipeline_report` | Generates the legacy run report (git commit, parameters, sequence attrition plots) — see the [Output Reference](../reference/outputs.md#execution_report). |
| `pipeline_utils_rs` | A collection of atomic sequence/alignment operations (translation, trimming, filtering, consensus, etc.), bundled into a single custom command-line tool rather than left as disconnected scripts — see [Custom tools](#custom-tools) below. |
| `prank` | Runs PRANK, one of the alignment tools evaluated in the aligner benchmark, notable for its phylogeny-aware indel placement. |
| `probcons` | Runs PROBCONS, one of the alignment tools evaluated in the aligner benchmark. |
| `seqtk` | Wraps `seqtk subseq` to extract a named subset of sequences from a FASTA file. |
| `strip` | Removes a given character (e.g. gap characters) from a sequence file. |
| `tcoffee` | Runs T-Coffee in its default and regressive modes, both evaluated in the aligner benchmark. |
| `utils` | Small housekeeping operations that don't warrant their own module: concatenating FASTA/JSON files, merging MAFFT profile-alignment indices, and removing a reference sequence from an alignment. |
| `virulign` | Runs VIRULIGN, a codon-aware aligner that trims and can discard frameshifted sequences during alignment — see the [aligner benchmark caveats](../reference/aligners.md#caveats). |

## Subworkflows (`subworkflows/local/`)

| Subworkflow | Description |
|---|---|
| `length_based_filtering` | Implements the `LENGTH_BASED_FILTERING` functional filter method: trim-to-stop, followed by length filtering and optional k-mer filtering. |
| `merge_by_group` | Concatenates sample files that share a `group` in the samplesheet into a single file, so they are aligned together rather than independently. |
| `pre_alignment_process` | Translates, collapses duplicate sequences, and (optionally) adds a reference sequence, in preparation for alignment. |
| `trim_aga` | Preprocessing via AGA — extracts the region of interest for sequences with complex reading frame structures. |
| `trim_minimap` | Preprocessing via `minimap2` — maps reads to the reference and trims them to the mapped coordinates. |

## Custom tools

Two of the tools driving the modules above were purpose-built for this pipeline rather
than adopted from existing bioinformatics software: `pipeline-utils-rs` and
`functional-filter`. `pipeline-utils-rs` in particular exists because the pipeline
consists of many small, atomic operations on sequence and alignment files — translation,
trimming, collapsing, filtering, and so on — and bundling these into one command-line
tool avoided scattering that logic across numerous disconnected scripts.
`functional-filter` implements the sequence-inclusion criteria agreed upon for functional
filtering (see [Stage 2 — Functional Filtering](../index.md#stage-2-functional-filtering)).
Both are described in more detail, with example CLI help output, in thesis Appendix D.4.

A third custom tool, `rusty-MetAL`, is not part of the pipeline itself — it implements the
MetAL distance measure used to compare aligners' output in the benchmark behind the
[Aligner Reference](../reference/aligners.md), and was built and used independently of
DeepLEAP's runtime.
