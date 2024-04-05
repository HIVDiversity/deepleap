nextflow.enable.dsl=2

include {COATI_PREPROCESS_READS} from "./main"

workflow{
    main:
    input_file = file("/home/dlejeune/masters/nf-test-data/test_seqs.fa")
    reference_file = file("/home/dlejeune/masters/nf-test-data/ref.fa")

    COATI_PREPROCESS_READS(
        input_file,
        reference_file
    )

    
}