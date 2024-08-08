
include {MAFFT} from "../../../modules/local/mafft/main"
include {ADJUST} from "../../../modules/local/adjust/main"
include {EXPAND} from "../../../modules/local/aligment_utils/main"

workflow CODON_ALIGNMENT{
    take:
    sample_tuple 

    main:


    input_file = file(sample_tuple[0])

    MAFFT(
        input_file
    )

    ADJUST (
        MAFFT.out.fasta
    )

    EXPAND(
        ADJUST.out.fasta,
        sample_tuple[1]

    )




    emit:
    EXPAND.out.fasta

}