include {PREPROCESS} from "./main.nf"

workflow{

    input_file = file("/home/dlejeune/masters/nf-test-data/small_test.fasta")
    ref_file = file("/home/dlejeune/masters/nf-test-data/small_test_ref.fasta")

    meta = [
        sample_id: "Test123"
    ]

    file_ch = channel.of([input_file, meta])
    file_ch.view()

    PREPROCESS(
        file_ch,
        ref_file
    )

    PREPROCESS.out.sample_tuple.view()

}