# Phylogeny + Heatmap Subworkflow

## Goal

Add a new opt-in subworkflow, `PHYLOGENY`, that infers a phylogenetic tree
from a computed MSA (via the existing but currently-unused `IQTREE` module)
and wires up (but does not yet implement) a per-site variation heatmap drawn
alongside that tree. This is a wiring task: channels, params, module
interfaces, and config need to exist and run end-to-end. The actual heatmap
rendering logic is a placeholder for now.

## Trigger

New param `params.build_phylogeny = false`. When `true`, `MAIN_WORKFLOW`
calls `PHYLOGENY` after the `ALIGN`/`POSTPROCESS` blocks it already runs.

This is independent of (and unrelated to) `MULTI_TIMEPOINT_ALIGNMENT`, which
is no longer used in practice; it is referenced here only as a structural
precedent for "opt-in subworkflow invoked from `MAIN_WORKFLOW`", not as an
active integration point.

## Inputs

`PHYLOGENY` takes a single alignment channel plus reference/config:

- `alignment_tuples` — `(file, meta)` tuples, where `meta` carries an
  `alignment_type` key of `"NT"` or `"AA"`. Built by `MAIN_WORKFLOW`, not by
  `PHYLOGENY` itself.
- `ch_reference` — the pipeline's `ch_reference_file` value channel.
- `baseline_method` — string param (see below).

`MAIN_WORKFLOW` builds `alignment_tuples` based on a new param
`params.phylogeny_alignment_type = "NT"` (one of `NT`, `AA`, `BOTH`):

- `NT` source: `ch_postprocess_nt` (i.e. `POSTPROCESS.out.reverse_translated_tuples`,
  or `ALIGN.out.aligned_tuple` when `is_nt_aligner` is true) — the same value
  already emitted as `sample_tuples_aligned_nt`.
- `AA` source: `ALIGN.out.aligned_tuple` directly — the raw align-step
  output, **not** `POSTPROCESS.out.sample_tuples_aligned_aa` (the
  expand/collapse postprocess variant).
- `BOTH`: both channels are tagged (`meta + [alignment_type: "NT"/"AA"]`) and
  mixed into one channel. Tagging keeps NT/AA tree/heatmap outputs for the
  same `sample_id` from colliding downstream, since `meta` (the whole map) is
  used as the join key throughout `PHYLOGENY`.

## Baseline selection

New param `params.phylogeny_baseline_method = "REFERENCE"`, one of
`REFERENCE`, `CONSENSUS`, `MINDIST`. Selected via Groovy `if`/`else` on the
param string inside `PHYLOGENY` (matching the existing aligner-selection
pattern in `workflows/align/main.nf`), not a per-record branch:

- `REFERENCE`: pair each alignment tuple with `ch_reference` via `.merge()`
  (same pattern `POSTPROCESS` already uses to pair a per-sample queue channel
  with a broadcastable reference channel).
- `CONSENSUS`: run the existing, currently-unused `GET_CONSENSUS` module
  (`modules/local/pipeline_utils_rs/consensus/main.nf`) on `alignment_tuples`.
  No new module needed.
- `MINDIST`: run a new stub module `MINDIST`
  (`modules/local/mindist/main.nf`) with the same `(file, meta) -> (file, meta)`
  interface as `GET_CONSENSUS`, placeholder script only
  (`touch ${meta.sample_id}.mindist.fasta`), to be implemented later.

All three paths converge into one `ch_baseline` channel of `(file, meta)`
tuples.

## Tree inference

`IQTREE(alignment_tuples)` — used as-is; no changes to the existing module.
Its output `tree_tuple` (`file("*.tree*")`, `meta`) is passed through
unchanged.

## Heatmap (placeholder)

New stub module `DRAW_TREE_HEATMAP`
(`modules/local/draw_tree_heatmap/main.nf`):

```
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

Inputs are joined by `meta` (the default join key) across the tree,
alignment, and baseline channels:

```
ch_tree_keyed      = IQTREE.out.tree_tuple.map { tree, meta -> [meta, tree] }
ch_alignment_keyed = alignment_tuples.map { file, meta -> [meta, file] }
ch_baseline_keyed  = ch_baseline.map { file, meta -> [meta, file] }

ch_heatmap_input = ch_tree_keyed
    .join(ch_alignment_keyed)
    .join(ch_baseline_keyed)
    .map { meta, tree, alignment, baseline -> [tree, alignment, baseline, meta] }
```

No actual heatmap rendering logic is implemented in this task — the module
exists so the full channel path from MSA → tree → baseline → drawing step is
runnable end-to-end today.

## `PHYLOGENY` subworkflow shape

`workflows/phylogeny/main.nf`:

```
workflow PHYLOGENY {
    take:
    alignment_tuples // (file, meta), meta.alignment_type = NT|AA
    ch_reference      // value channel
    baseline_method   // string param

    main:
    IQTREE(alignment_tuples)

    if (baseline_method == "REFERENCE") {
        ch_baseline = alignment_tuples.merge(ch_reference) { sample, ref -> [ref, sample[1]] }
    }
    else if (baseline_method == "CONSENSUS") {
        GET_CONSENSUS(alignment_tuples)
        ch_baseline = GET_CONSENSUS.out.sample_tuple
    }
    else if (baseline_method == "MINDIST") {
        MINDIST(alignment_tuples)
        ch_baseline = MINDIST.out.sample_tuple
    }

    // join tree + alignment + baseline by meta, run DRAW_TREE_HEATMAP

    emit:
    tree_tuple    = IQTREE.out.tree_tuple
    baseline_tuple = ch_baseline
    heatmap_tuple = DRAW_TREE_HEATMAP.out.heatmap_tuple
}
```

## `MAIN_WORKFLOW` integration

```
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
```

New `MAIN_WORKFLOW` params (added to its `take:` block, wired through from
top-level `workflow {}` in `main.nf`, same as `multi_timepoint_alignment`
today): `build_phylogeny`, `phylogeny_alignment_type`,
`phylogeny_baseline_method`.

New emits: `phylogeny_tree`, `phylogeny_baseline`, `phylogeny_heatmap`.

## Config and schema

`nextflow.config`:

```
build_phylogeny = false
phylogeny_alignment_type = "NT"      // NT, AA, BOTH
phylogeny_baseline_method = "REFERENCE"  // REFERENCE, CONSENSUS, MINDIST
```

`conf/modules.config` — new `withName` blocks for `MINDIST` and
`DRAW_TREE_HEATMAP`. Both are placeholder stubs, so a minimal generic
container (`ubuntu:22.04`) is used until real implementations land:

```
withName: MINDIST {
    container = "ubuntu:22.04"
}

withName: DRAW_TREE_HEATMAP {
    container = "ubuntu:22.04"
}
```

`IQTREE` already has a `withName` block (`dlejeune/iqtree:2.0.7`,
`ext.args = params.iqtree_args`) — no change needed. `GET_CONSENSUS` is
covered by the existing `withLabel: pipeline_utils_rs` block.

`nextflow_schema.json` — new `phylogeny_options` definition group for the
three new params, referenced from the schema's top-level `allOf`.

## Output publishing

New entries in `main.nf`'s top-level `publish:`/`output {}` blocks,
namespaced under `phylogeny/` and including `alignment_type` in the path so
NT/AA outputs never collide when `phylogeny_alignment_type = BOTH`:

```
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
```

## Testing

Each new/changed module gets a `test.nf` following the existing convention
(see `modules/local/iqtree/test.nf`, `modules/local/pipeline_utils_rs/consensus/test.nf`):

- `modules/local/mindist/test.nf`
- `modules/local/draw_tree_heatmap/test.nf`

The `PHYLOGENY` subworkflow gets a `workflows/phylogeny/test.nf` exercising
at least the `REFERENCE` baseline path end-to-end (MSA in → tree + baseline +
heatmap placeholder out).

## Out of scope

- Actual heatmap rendering (per-site variation computation/drawing) —
  `DRAW_TREE_HEATMAP`'s script stays a `touch` placeholder.
- Real `MINDIST` baseline computation.
- Any change to `MULTI_TIMEPOINT_ALIGNMENT` (unused, left as-is).
- Tree visualization/rendering beyond the raw IQTREE output file.
