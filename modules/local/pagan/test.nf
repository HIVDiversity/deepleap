include { PAGAN } from "./main"

workflow {
    input_file = file("/home/dlejeune/masters/nf-test-data/alignment_test/collapsed_input.fasta")
    meta = ["sample_id": "TEST"]

    input_ch = channel.from([[input_file, meta]])

    PAGAN(
        input_ch
    )
}
