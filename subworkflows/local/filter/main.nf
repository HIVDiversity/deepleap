
include {AGA} from "../../../modules/local/aga/main"
include {FILTER_AGA_OUTPUT} from "../../../modules/local/filter_aga/main"

workflow FILTER{
    take:
    sample_tuple // path(input), val(meta)
    genbankFile

    main:

    AGA(
        sample_tuple,
        genbankFile

    )

    FILTER_AGA_OUTPUT(
        AGA.out.aa_alignment
    )

    emit:
    filtered_aga_output = FILTER_AGA_OUTPUT.out.filtered_tuples
    aga_nt_alignments = AGA.out.nt_alignment

}