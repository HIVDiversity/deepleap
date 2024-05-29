nextflow.enable.dsl=2

include {TCOFFEE} from "./main"

workflow{

    main:

    read_file = file("/home/dlejeune/masters/nf-test-data/test_two_seqs.fa")

    TCOFFEE(
        read_file
    )
    

}