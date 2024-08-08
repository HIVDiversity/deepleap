nextflow.enable.dsl=2

include {ADJUST} from "./main.nf"

workflow {
    main:

        input_file = file("/home/dlejeune/masters/nf-test-data/mafft_aligned_small_test.fasta")

        ADJUST(
            input_file
        )
}