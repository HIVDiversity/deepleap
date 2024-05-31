nextflow.enable.dsl=2

include {COLLAPSE} from "./main"

workflow {

    main:

    read_file = file("/home/dlejeune/masters/nf-test-data/test_two_seqs.fa")

    COLLAPSE(
        read_file,
        "123"
    )
    

}