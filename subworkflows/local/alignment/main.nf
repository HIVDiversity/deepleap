
include {MAFFT} from "../../../modules/local/mafft/main"
include {ADJUST} from "../../../modules/local/adjust/main"
include {EXPAND} from "../../../modules/local/aligment_utils/main"

workflow CODON_ALIGNMENT{
    take:
    sample_tuple // path(input), val(meta)
    namefile_tuple // path(namefile), val(meta)

    main:

    MAFFT(
        sample_tuple
    )

    // ADJUST (
    //     MAFFT.out.sample_tuple
    // )

    // sample_namefile_ch = ADJUST.out.sample_tuple.join(namefile_tuple, by: 1)

    // EXPAND(
    //     sample_namefile_ch
    // )




    emit:
    MAFFT.out.sample_tuple

}