include { MINDIST } from "./main"

workflow {
    def alignment = file("${projectDir}/test-data/aligned.fasta")
    def meta = ["sample_id": "seqtest"]

    def in_ch = channel.of([alignment, meta])

    MINDIST(
        in_ch
    )

    MINDIST.out.sample_tuple.view()
}
