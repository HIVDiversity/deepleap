---
icon: lucide/list-tree
---

# Parameter Reference

Every pipeline parameter, grouped by pipeline stage. `nextflow_schema.json` at the repo root
is the source of truth for types, defaults, and validation.

For a walkthrough of the parameters needed for a first run, see
[Running the CLI](../user-guide/running-cli.md).

!!! note "`--` vs `-`"
    Pipeline parameters (listed below) are passed with a double dash, e.g. `--aligner MAFFT`.
    Nextflow's own built-in options use a single dash, e.g. `-profile`, `-output-dir`, `-c`.

## Core parameters

Required for every run.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `run_name` | string | *(required)* | Identifier for this run. Used in logging, reports, and the default output path. |
| `samplesheet` | file path | *(required)* | CSV of samples and metadata. See [Samplesheet Reference](samplesheet.md). |
| `sample_base_dir` | directory path | *(required)* | Base directory for resolving samplesheet file paths. |
| `reference_file` | file path | *(required)* | Reference sequence containing the gene/CDS of interest. Expected format depends on `trim_method`. |
| `region_of_interest` | string | *(required)* | CDS or protein to extract. Required even without AGA preprocessing; no fixed naming convention. |
| `-output-dir` | directory path | `./results/${run_name}` | Nextflow built-in, not a pipeline parameter. Where output files are saved. |

## Preprocessing parameters

Stage 1 (Trim) — see [Pipeline Overview](../index.md#stage-1-preprocessing-trim).

| Parameter | Type | Default | Description |
|---|---|---|---|
| `trim_method` | enum: `MINIMAP2`, `AGA` | `AGA` | Trimming tool. `MINIMAP2` is faster; `AGA` handles complex overlapping reading frames. |
| `skip_trim` | boolean | `false` | Skip trimming — input is already trimmed to the region of interest. |
| `region_shorthand` | string | *(none)* | Short name for the region of interest. |
| `aga_args` | string | `--local` | Extra arguments for AGA. |
| `minimap_trim_from` | integer | *(none)* | Start coordinate for MINIMAP2 trimming. |
| `minimap_trim_to` | integer | *(none)* | End coordinate for MINIMAP2 trimming. |

## Filtering parameters

Stage 2 (Functional Filtering) — see [Pipeline Overview](../index.md#stage-2-functional-filtering).

| Parameter | Type | Default | Description |
|---|---|---|---|
| `functional_filter_method` | enum: `ELLPACA`, `LENGTH_BASED_FILTERING` | `ELLPACA` | `ELLPACA` filters on stop codons (below); `LENGTH_BASED_FILTERING` filters on length (next section). |
| `skip_functional_filter` | boolean | `false` | Skip functional filtering — all sequences proceed to alignment. |
| `ff_max_stop_pct` | integer | `100` | Latest point along the read (as a percentage) a stop codon can occur and still count as functional. |
| `ff_include_no_stop_codons` | boolean | `true` | Whether sequences with no stop codons are functional. |
| `ff_include_frameshifts` | boolean | `false` | Whether sequences with a potential frameshift are functional. |
| `ff_acceptable_pct_loss` | number (0–1) | `0.2` | Proportion of median protein length allowed to be lost before a sequence is non-functional. |
| `ff_expected_length` | number | *(median of input)* | Expected protein length. Unset uses the median of the input. |

### Length-based filtering

Used when `functional_filter_method` is `LENGTH_BASED_FILTERING`.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `lbf_threshold_mode` | enum: `FIXED`, `MEDIAN`, `MEAN` | `MEDIAN` | How the minimum-length threshold ("center") is determined. |
| `lbf_min_length` | integer | *(none)* | Minimum length to keep. Required, and only used, in `FIXED` mode. |
| `lbf_tolerance` | string (e.g. `20`, `20%`) | *(none — strict minimum)* | Sets both `lbf_min_tolerance` and `lbf_max_tolerance` to the same value. Not combinable with either. |
| `lbf_min_tolerance` | string (e.g. `20`, `20%`) | *(none)* | How much shorter than center a sequence may be. Not combinable with `lbf_tolerance`. |
| `lbf_max_tolerance` | string (e.g. `20`, `20%`) | *(none — no upper bound)* | How much longer than center a sequence may be. Not combinable with `lbf_tolerance`. |

### K-mer filtering

Independent filtering pass matching sequence ends against expected k-mers.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `use_kmer_filtering` | boolean | `false` | Turns k-mer filtering on. |
| `match_kmers_start` | string | *(none)* | K-mer(s) to match at the sequence start. Comma-separated. |
| `match_kmers_end` | string | *(none)* | K-mer(s) to match at the sequence end. Comma-separated. |

## Alignment parameters

Stage 3 (Alignment) — see [Aligner Reference](aligners.md) for choosing an aligner.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `aligner` | enum (see [Aligner Reference](aligners.md)) | `MAFFT` | Aligner used for the main alignment. |

Pass-through arguments, one per aligner:

| Parameter | Default | Applies to |
|---|---|---|
| `mafft_args` | `--localpair --maxiterate 1000` | MAFFT |
| `mafft_fast_align_args` | `--retree 1 --maxiterate 0` | MAFFT, used internally by AGA's preprocessing |
| `tcoffee_args` | *(none)* | T-Coffee |
| `tcoffee_regressive_args` | `-nseq 100 -tree mbed -method clustalo_msa` | T-Coffee Regressive |
| `prank_args` | `+F` | PRANK |
| `pagan_args` | *(none)* | PAGAN |
| `clustalo_args` | `--iterations 2` | Clustal Omega |
| `clustalw_args` | `-CLUSTERING=NJ -ITERATION=NONE -NUMITER=3 -MATRIX=BLOSUM` | ClustalW |
| `virulign_args` | `--maxFrameShifts 3 --exportReferenceSequence no` | VIRULIGN |
| `macse_args` | *(none)* | MACSE |

MUSCLE, MUSCLE-FAST, and PROBCONS have no pass-through arguments parameter.

### Panel alignment

| Parameter | Type | Default | Description |
|---|---|---|---|
| `panel_alignment` | file path | *(none)* | Pre-aligned sequences used as a scaffold, when `aligner` is `MAFFT-SEED`. |

### Reference sequence insertion

Inserts a reference sequence directly into the alignment, instead of mapping it on afterward.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `add_reference_to_sequences` | enum: `BEFORE`, `AFTER`, `null` | `null` | Whether, and where, a reference is added to the sequences being aligned. `null` disables this. |
| `reference_to_add` | file path | *(none)* | Reference sequence to insert. Can differ from `reference_file`, which is used for trimming/mapping. |

## Phylogeny parameters

Infers a phylogenetic tree from the computed alignment(s).

| Parameter | Type | Default | Description |
|---|---|---|---|
| `build_phylogeny` | boolean | `false` | Infer a phylogenetic tree from the computed alignment(s). |
| `phylogeny_alignment_type` | enum: `NT`, `AA`, `BOTH` | `NT` | Which computed alignment(s) feed tree inference. |
| `phylogeny_baseline_method` | enum: `REFERENCE`, `CONSENSUS`, `MINDIST` | `REFERENCE` | How the baseline sequence for tree rooting is chosen. Also intended for a per-site variation heatmap, not yet implemented. |
| `iqtree_args` | string | *(none)* | Extra arguments for IQ-TREE, when `build_phylogeny` is enabled. |

!!! warning "Deprecated"
    `multi_timepoint_alignment` is deprecated. Don't use it in new runs.

## Execution / resource parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `-profile` | string | *(none)* | Nextflow config profile(s). Container runtimes: `docker`, `singularity`, `apptainer`. Others: `test` (caps resources for the test dataset), `debug` (verbose logging, no cleanup), `slurm`. Site-specific: `ilifu`, `hex`, `zoidberg` — see the [Developer Guide](../developer-guide/architecture.md) to add your own. |
| `max_memory` | string | `128.GB` | Memory cap per process. |
| `max_cpus` | integer | `16` | CPU cap per process. |
| `max_time` | string | `240.h` | Time cap per process. |
| `slurm_queue` | string | `Main` | SLURM queue, when using the `slurm` profile. |
