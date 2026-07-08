include { TRIM_AGA } from "../../subworkflows/local/trim_aga/main"
include { TRIM_MINIMAP } from "../../subworkflows/local/trim_minimap/main"
include { LENGTH_BASED_FILTERING } from "../../subworkflows/local/length_based_filtering/main"
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
    functional_filter_method
    use_kmer_filtering
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
        else if (trim_method == "MINIMAP2") {
            TRIM_MINIMAP(
                ch_input_files,
                ch_reference_file,
                trim_coords,
            )
            ch_preprocessed_files_nt = TRIM_MINIMAP.out.preprocessed_nt_seqs
        }
        else {
            error("Preprocessing type not recognized: ${trim_method}")
        }
    }
    else {
        ch_preprocessed_files_nt = ch_input_files
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // FUNCTIONAL FILTERING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    if (!skip_functional_filter) {
        if (functional_filter_method == "ELLPACA") {
            FUNCTIONAL_FILTER(
                ch_preprocessed_files_nt
            )
            ch_functional_filter_out = FUNCTIONAL_FILTER.out.filtered_tuples
            ch_ff_report = FUNCTIONAL_FILTER.out.report
            ch_ff_rejected = FUNCTIONAL_FILTER.out.rejected_records
            ch_ff_trimmed_to_stop = channel.empty()
        }
        else if (functional_filter_method == "LENGTH_BASED_FILTERING") {
            LENGTH_BASED_FILTERING(
                ch_preprocessed_files_nt,
                use_kmer_filtering,
            )
            ch_functional_filter_out = LENGTH_BASED_FILTERING.out.filtered_tuples
            ch_ff_report = LENGTH_BASED_FILTERING.out.report
            ch_ff_rejected = LENGTH_BASED_FILTERING.out.rejected_records
            ch_ff_trimmed_to_stop = LENGTH_BASED_FILTERING.out.trimmed_to_stop_nt
        }
        else {
            error("Functional filter method not recognized: ${functional_filter_method}")
        }
    }
    else {
        ch_functional_filter_out = ch_preprocessed_files_nt
        ch_ff_report = channel.empty()
        ch_ff_rejected = channel.empty()
        ch_ff_trimmed_to_stop = channel.empty()
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
    sample_tuples_length_trimmed_nt = ch_ff_trimmed_to_stop
}
