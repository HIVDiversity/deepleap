include { DRAW_TREE_HEATMAP } from "./main"

workflow {
    def tree = file("${projectDir}/test-data/tree.tree")
    def alignment = file("${projectDir}/test-data/aligned.fasta")
    def baseline = file("${projectDir}/test-data/baseline.fasta")
    def meta = ["sample_id": "seqtest"]

    def in_ch = channel.of([tree, alignment, baseline, meta])

    DRAW_TREE_HEATMAP(
        in_ch
    )

    DRAW_TREE_HEATMAP.out.heatmap_tuple.view()
}
