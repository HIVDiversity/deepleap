
include {MAFFT} from "../../../modules/local/mafft/main"
include {ADJUST} from "../../../modules/local/adjust/main"

workflow CODON_ALIGNMENT{
    take:
    input_file 

    main:


    input_file = file(input_file)

    MAFFT(
        input_file
    )

    ADJUST (
        MAFFT.out.fasta
    )




    emit:
    MAFFT.out.fasta
    ADJUST.out.fasta

}