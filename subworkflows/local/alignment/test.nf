include {CODON_ALIGNMENT} from "./main"


workflow{

    input_file = file("/home/dlejeune/masters/nf-test-data/alignment_test/collapsed_input.fasta")
    name_file = file("/home/dlejeune/masters/nf-test-data/alignment_test/names.json")
    input_channel = channel.of([input_file, name_file])

    CODON_ALIGNMENT(
        [input_file, name_file]
    )


    // CODON_ALIGNMENT.out.view()

}