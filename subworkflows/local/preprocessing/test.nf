include {PREPROCESS} from "./main.nf"

workflow{

    input_file = file("/home/dlejeune/masters/nf-test-data/small_test.fasta")
    ref_file = file("/home/dlejeune/masters/nf-test-data/small_test_ref.fasta")

    PREPROCESS(
        input_file,
        ref_file
    )

    PREPROCESS.out.sample_tuple.view()

}