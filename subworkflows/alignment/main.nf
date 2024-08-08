
include {MAFFT} from "../../../modules/local/mafft/main"

workflow CODON_ALIGNMENT{
    take:
    input_file 

    main:


    input_file = file(input_file)

    MAFFT(
        input_file
    )


    emit:
    MAFFT.out.fasta

}