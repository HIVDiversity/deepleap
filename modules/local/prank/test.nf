include { PRANK } from "./main"
workflow {

    in_file = file("/home/dlejeune/masters/nf-test-data/test_whole_pipeline/new_test/samples/CAP001_1000.fasta")
    meta = ["sample_id": "TEST"]

    in_ch = channel.from([[in_file, meta]])

    PRANK(
        in_ch
    )
}
