include {CODON_ALIGNMENT} from "./main"


workflow{

    input_file = file("/home/dlejeune/masters/nf-test-data/test_seqs.fa")

    CODON_ALIGNMENT(
        input_file
    )


    // CODON_ALIGNMENT.out.view()

}