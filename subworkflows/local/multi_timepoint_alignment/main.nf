include { MAFFT_ADD_PROFILE } from "../../../modules/local/mafft/main"

workflow MULTI_TIMEPOINT_ALIGNMENT {
    take:
    timepoint_tuples // str(CAP_ID), list(file_a, file_b, file_c)

    main:

    MAFFT_ADD_PROFILE(
        timepoint_tuples
    )

    emit:
    profile_aligment = MAFFT_ADD_PROFILE.out.profile_alignment_tuple
}
