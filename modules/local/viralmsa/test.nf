nextflow.enable.dsl=2

include {VIRALMSA} from "./main"

workflow{

    main:

    read_file = file("/home/dlejeune/masters/nf-test-data/test_two_seqs.fa")
    ref_file = file("/home/dlejeune/masters/nf-test-data/ref.fa")

    VIRALMSA(
        read_file,
        ref_file
    )
    

}