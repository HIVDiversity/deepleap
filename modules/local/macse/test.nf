include { MACSE } from "./main"

workflow {
    input_file = file("/home/dlejeune/masters/nf-test-data/test_whole_pipeline/new_test/samples/CAP001_1000.fasta")
    meta = ["sample_id": "TEST"]

    input_ch = channel.from([[input_file, meta]])

    MACSE(
        input_ch
    )

    MACSE.out.sample_tuple.view()
}
