include { PHYLOGENY } from "./main"

workflow {
    def alignment = file("${projectDir}/test-data/aligned.fasta")
    def reference = file("${projectDir}/test-data/reference.fasta")
    def meta = ["sample_id": "seqtest", "alignment_type": "NT"]

    def alignment_ch = channel.of([alignment, meta])
    def reference_ch = channel.value(reference)

    PHYLOGENY(
        alignment_ch,
        reference_ch,
        "REFERENCE",
    )

    PHYLOGENY.out.tree_tuple.view { v -> "TREE: $v" }
    PHYLOGENY.out.baseline_tuple.view { v -> "BASELINE: $v" }
    PHYLOGENY.out.heatmap_tuple.view { v -> "HEATMAP: $v" }
}
