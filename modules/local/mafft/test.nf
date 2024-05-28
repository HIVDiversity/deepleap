nextflow.enable.dsl=2

include {MAFFT} from "./main"

workflow{

    main:

    read_file = file("/home/dlejeune/masters/nf-test-data/test_two_seqs.fa")

    MAFFT(
        read_file
    )
    

}