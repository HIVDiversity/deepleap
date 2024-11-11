
include {AGA} from "../../../modules/local/aga/main"
include {FILTER_AGA_OUTPUT} from "../../../modules/local/filter_aga/main"
include {STRIP} from "../../../modules/local/strip/main"

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

    STRIP(
        FILTER_AGA_OUTPUT.out.filtered_tuples,
        channel.value(".") // We want to remove any dots from the alignments.
    )

    emit:
    filtered_aga_output = STRIP.out.sample_tuple
    aga_nt_alignments = AGA.out.nt_alignment

}