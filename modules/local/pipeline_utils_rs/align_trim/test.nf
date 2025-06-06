include { PAIRWISE_ALIGN_TRIM } from "./main"

workflow {

    query_file = file("/home/dlejeune/masters/nf-test-data/test_trim_consensus/CAP344_2000-pool1_nicd.consensus.fasta")
    reference_file = file("/home/dlejeune/masters/nf-test-data/test_trim_consensus/hxb2.fasta")
    meta = ["sample_id": "CAP344_2000-pool1_nicd"]

    input_ch = channel.from([[query_file, meta]])
    ref_ch = channel.of(reference_file)

    PAIRWISE_ALIGN_TRIM(
        input_ch,
        ref_ch,
        "VERBOSE",
    )

    PAIRWISE_ALIGN_TRIM.out.view()
}
