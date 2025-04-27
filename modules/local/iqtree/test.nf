include { IQTREE } from "./main"

workflow {
    def alignment = file("/home/dlejeune/masters/nf-test-data/test_iqtree/CAP008_3100-pool4_earlham.reverse_translated.fasta")

    def meta = ["sample_id": "CAP001"]

    def in_ch = channel.of([alignment, meta])

    IQTREE(
        in_ch
    )

    IQTREE.out.tree_tuple.view()
}
