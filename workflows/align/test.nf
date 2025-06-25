include { ALIGN } from "./main"
workflow {
    def input_file = file("/home/dlejeune/masters/nf-test-data/test_align_subworkflow/CAP409_2000-pool12_inqaba.collapsed.fasta")

    def meta = ["sample_id": "CAP409_2000-pool12_inqaba"]

    def input_ch = channel.from([[input_file, meta]])

    ALIGN(
        input_ch
    )
}
