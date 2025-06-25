include { TRIM_AGA } from "../../subworkflows/local/trim_aga/main"
include { TRIM_CUSTOM } from "../../subworkflows/local/trim_custom/main"
include { PRE_ALIGNMENT_PROCESSING } from "../../subworkflows/local/pre_alignment_process/main"
include { FUNCTIONAL_FILTER } from "../../modules/local/functional_filter/main"
workflow PREPROCESS {
    take:
    ch_input_files
    ch_reference_file
    preprocessing_type
    ch_refToAdd
    add_ref_before_align

    main:

    if (preprocessing_type == "AGA") {
        TRIM_AGA(
            ch_input_files,
            ch_reference_file,
        )

        preprocessed_files_nt = TRIM_AGA.out.preprocessed_nt_seqs
    }
    else if (preprocessing_type == "CUSTOM") {
        TRIM_CUSTOM(
            ch_input_files,
            ch_reference_file,
            params.use_kmer_trimming,
        )

        preprocessed_files_nt = TRIM_CUSTOM.out.preprocessed_nt_seqs
    }
    else {
        println("Preprocessing type not reconized.")
        exit(1)
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // FUNCTIONAL FILTERING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    FUNCTIONAL_FILTER(
        preprocessed_files_nt
    )

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // TRANSLATE - COLLAPSE - ADD REF (OPTIONAL)
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    PRE_ALIGNMENT_PROCESSING(
        FUNCTIONAL_FILTER.out.filtered_tuples,
        add_ref_before_align,
        ch_refToAdd,
    )

    emit:
    sample_tuples_aa = PRE_ALIGNMENT_PROCESSING.out.sample_tuples_aa
    sample_tuples_nt = PRE_ALIGNMENT_PROCESSING.out.sample_tuples_nt
    namefile_tuples = PRE_ALIGNMENT_PROCESSING.out.namefile_tuples
    sample_tuples_rejected_nt = FUNCTIONAL_FILTER.out.rejected_records
    filter_report = FUNCTIONAL_FILTER.out.report
}
