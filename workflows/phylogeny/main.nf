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
