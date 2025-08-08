include { VIRALMSA } from "./main"

workflow {
    input_file = file("/home/dlejeune/masters/nf-test-data/alignment_test/collapsed_input.fasta")
    meta = ["sample_id": "TEST"]

    input_ch = channel.from([[input_file, meta]])
    reference = channel.of(file("/home/dlejeune/masters/nf-test-data/test_whole_pipeline/hxb2-env.fasta"))

    VIRALMSA(
        input_ch,
        reference,
    )

    VIRALMSA.out.sample_tuple.view()
}
