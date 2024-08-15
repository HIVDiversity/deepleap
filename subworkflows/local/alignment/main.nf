
include {MAFFT} from "../../../modules/local/mafft/main"
include {ADJUST} from "../../../modules/local/adjust/main"
include {EXPAND} from "../../../modules/local/aligment_utils/main"

workflow CODON_ALIGNMENT{
    take:
    sample_tuple 

    main:

    MAFFT(
        sample_tuple
    )

    ADJUST (
        MAFFT.out.fasta
    )

    EXPAND(
        ADJUST.out.fasta,
        sample_tuple.map{it -> it[1]}

    )




    emit:
    EXPAND.out.fasta

}