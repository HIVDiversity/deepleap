include { IQTREE } from "../../modules/local/iqtree/main"
include { GET_CONSENSUS } from "../../modules/local/pipeline_utils_rs/consensus/main"
include { MINDIST } from "../../modules/local/pipeline_utils_rs/mindist/main"
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

    def add_baseline_id = { fasta, meta ->
        def seq_name = fasta.text.readLines().find { line -> line.startsWith('>') } - '>'
        [fasta, meta + [baseline_id: seq_name.trim()]]
    }

    def ch_baseline
    if (baseline_method == "REFERENCE") {
        ch_baseline = alignment_tuples.merge(ch_reference) { sample, ref -> [ref, sample[1] + [baseline_id: sample[1].ref_seq_name]] }
    }
    else if (baseline_method == "CONSENSUS") {
        GET_CONSENSUS(
            alignment_tuples
        )
        ch_baseline = GET_CONSENSUS.out.sample_tuple.map(add_baseline_id)
    }
    else if (baseline_method == "MINDIST") {
        MINDIST(
            alignment_tuples
        )
        ch_baseline = MINDIST.out.sample_tuple.map(add_baseline_id)
    }
    else {
        error("Unrecognized phylogeny_baseline_method: ${baseline_method}")
    }

    def ch_tree_keyed = IQTREE.out.tree_tuple.map { tree, meta -> [meta, tree] }
    def ch_alignment_keyed = alignment_tuples.map { file, meta -> [meta, file] }


    def ch_heatmap_input = ch_tree_keyed
        .join(ch_alignment_keyed)
        .map { meta, tree, alignment -> [tree, alignment, meta] }

    DRAW_TREE_HEATMAP(
        ch_heatmap_input
    )

    emit:
    tree_tuple = IQTREE.out.tree_tuple
    baseline_tuple = ch_baseline
    heatmap_tuple = DRAW_TREE_HEATMAP.out.tree_heatmap_tuple
}
