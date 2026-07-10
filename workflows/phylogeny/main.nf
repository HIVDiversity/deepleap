include { IQTREE } from "../../modules/local/iqtree/main"
include { GET_CONSENSUS } from "../../modules/local/pipeline_utils_rs/consensus/main"
include { FILTER_NAME } from "../../modules/local/pipeline_utils_rs/filter_name/main"
include { MINDIST } from "../../modules/local/pipeline_utils_rs/mindist/main"
include { DRAW_TREE_HEATMAP } from "../../modules/local/draw_tree_heatmap/main"

workflow PHYLOGENY {
    take:
    alignment_tuples // file, meta (meta.alignment_type = "NT" or "AA")
    ch_reference // value channel, raw reference file
    baseline_method // string param: REFERENCE, CONSENSUS, or MINDIST

    main:

    // Need to remove the reference from the alignment prior to tree construction
    // TODO: this should really be parameterized
    FILTER_NAME(
        alignment_tuples,
        alignment_tuples.map { _fasta, meta -> meta.ref_seq_name },
    )


    IQTREE(
        FILTER_NAME.out.filtered_tuples
    )


    def ch_baseline
    if (baseline_method == "REFERENCE") {
        ch_baseline = alignment_tuples.merge(ch_reference) { sample, ref -> [ref, sample[1] + [baseline_id: sample[1].ref_seq_name]] }
    }
    else if (baseline_method == "CONSENSUS") {
        GET_CONSENSUS(
            FILTER_NAME.out.filtered_tuples
        )
        ch_baseline = GET_CONSENSUS.out.sample_tuple
    }
    else if (baseline_method == "MINDIST") {
        MINDIST(
            FILTER_NAME.out.filtered_tuples
        )
        ch_baseline = MINDIST.out.sample_tuple
    }
    else {
        error("Unrecognized phylogeny_baseline_method: ${baseline_method}")
    }

    def ch_tree_keyed = IQTREE.out.tree_tuple.map { tree, meta -> [meta, tree] }
    def ch_alignment_keyed = FILTER_NAME.out.filtered_tuples.map { file, meta -> [meta, file] }
    def ch_baseline_keyed = ch_baseline.map { file, meta -> [meta, file] }


    def ch_heatmap_input = ch_tree_keyed
        .join(ch_alignment_keyed)
        .join(ch_baseline_keyed)
        .map { meta, tree, alignment, baseline -> [tree, alignment, baseline, meta] }

    def heatmap_ch
    if (false) {
        DRAW_TREE_HEATMAP(
            ch_heatmap_input
        )

        heatmap_ch = DRAW_TREE_HEATMAP.out.tree_heatmap_tuple
    }
    else {
        heatmap_ch = channel.empty()
    }

    emit:
    tree_tuple = IQTREE.out.tree_tuple
    baseline_tuple = ch_baseline
    heatmap_tuple = heatmap_ch
    phylogeny_misc_files = IQTREE.out.iqtree_output
}
