include { TRIM_AGA } from "../../subworkflows/local/trim_aga/main"
include { TRIM_CUSTOM } from "../../subworkflows/local/trim_custom/main"
include { TRIM_MINIMAP } from "../../subworkflows/local/trim_minimap/main"
include { PRE_ALIGNMENT_PROCESSING } from "../../subworkflows/local/pre_alignment_process/main"
include { FUNCTIONAL_FILTER } from "../../modules/local/functional_filter/main"
workflow PREPROCESS {
    take:
    ch_input_files
    ch_reference_file
    trim_method
    ch_refToAdd
    add_ref_before_align
    skip_trim
    skip_functional_filter
    trim_coords

    main:
    if (!skip_trim) {
        if (trim_method == "AGA") {
            TRIM_AGA(
                ch_input_files,
                ch_reference_file,
            )

            ch_preprocessed_files_nt = TRIM_AGA.out.preprocessed_nt_seqs
        }
        else if (trim_method == "CUSTOM") {
            TRIM_CUSTOM(
                ch_input_files,
                ch_reference_file,
                params.use_kmer_trimming,
            )

            ch_preprocessed_files_nt = TRIM_CUSTOM.out.preprocessed_nt_seqs
        }
        else if (trim_method == "MINIMAP2") {
            TRIM_MINIMAP(
                ch_input_files,
                ch_reference_file,
                trim_coords,
            )
            ch_preprocessed_files_nt = TRIM_MINIMAP.out.preprocessed_nt_seqs
        }
        else {
            println("Preprocessing type not reconized.")
            exit(1)
        }
    }
    else {
        ch_preprocessed_files_nt = ch_input_files
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // FUNCTIONAL FILTERING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    if (!skip_functional_filter) {
        FUNCTIONAL_FILTER(
            ch_preprocessed_files_nt
        )
        ch_functional_filter_out = FUNCTIONAL_FILTER.out.filtered_tuples
        ch_ff_report = FUNCTIONAL_FILTER.out.report
        ch_ff_rejected = FUNCTIONAL_FILTER.out.rejected_records
    }
    else {
        ch_functional_filter_out = ch_preprocessed_files_nt
        ch_ff_report = channel.empty()
        ch_ff_rejected = channel.empty()
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // TRANSLATE - COLLAPSE - ADD REF (OPTIONAL)
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    PRE_ALIGNMENT_PROCESSING(
        ch_functional_filter_out,
        add_ref_before_align,
        ch_refToAdd,
    )

    emit:
    sample_tuples_aa = PRE_ALIGNMENT_PROCESSING.out.sample_tuples_aa
    sample_tuples_nt = PRE_ALIGNMENT_PROCESSING.out.sample_tuples_nt
    namefile_tuples = PRE_ALIGNMENT_PROCESSING.out.namefile_tuples
    sample_tuples_rejected_nt = ch_ff_rejected
    filter_report = ch_ff_report
}
