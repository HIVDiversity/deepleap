include { COLLAPSE } from "./main"

workflow {

    sequences = file("/home/dlejeune/masters/nf-test-data/test_collapse/CAP409_2000-pool12_inqaba.translated.fasta")


    meta = ["sample_id": "CAP409_2000-pool12_inqaba"]

    input_ch = channel.from([[sequences, meta]])

    COLLAPSE(
        input_ch
    )

    COLLAPSE.out.sample_tuple.view()
}
