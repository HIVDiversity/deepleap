nextflow.enable.dsl=2

include {COATI} from "./main"

workflow{

    main:

    read_file = file("/home/dlejeune/masters/nf-test-data/test_two_seqs.fa")

    COATI(
        read_file
    )
    

}