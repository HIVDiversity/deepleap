include { TRIM_AGA } from "../../subworkflows/local/trim_aga/main"
include { TRIM_MINIMAP } from "../../subworkflows/local/trim_minimap/main"
include { LENGTH_BASED_FILTERING } from "../../subworkflows/local/length_based_filtering/main"
include { PRE_ALIGNMENT_PROCESSING } from "../../subworkflows/local/pre_alignment_process/main"
include { MERGE_BY_GROUP as MERGE_BEFORE_FILTER } from "../../subworkflows/local/merge_by_group/main"
include { MERGE_BY_GROUP as MERGE_BEFORE_ALIGN } from "../../subworkflows/local/merge_by_group/main"
include { FUNCTIONAL_FILTER } from "../../modules/local/functional_filter/main"

workflow PREPROCESS {
    take:
    ch_input_files
    ch_reference_file
    trim_method
    ch_refToAdd
    add_ref_before_align
    functional_filter_method
    use_kmer_filtering
    trim_coords

    main:
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // SEQUENCE TRIMMING (per-file: rows with skip_trim bypass)
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def to_trim = ch_input_files.filter { f, m -> !m.skip_trim }
    def bypass_trim = ch_input_files.filter { f, m -> m.skip_trim }

    def ch_trimmed
    if (trim_method == "AGA") {
        TRIM_AGA(to_trim, ch_reference_file)
        ch_trimmed = TRIM_AGA.out.preprocessed_nt_seqs
    }
    else if (trim_method == "MINIMAP2") {
        TRIM_MINIMAP(to_trim, ch_reference_file, trim_coords)
        ch_trimmed = TRIM_MINIMAP.out.preprocessed_nt_seqs
    }
    else {
        error("Preprocessing type not recognized: ${trim_method}")
    }

    def ch_after_trim = ch_trimmed.mix(bypass_trim)

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // FUNCTIONAL FILTERING (per-file: rows with skip_filter bypass)
    // Members that need filtering are merged per group first, so the filter
    // sees the whole group together (consistent length median).
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def to_filter = ch_after_trim.filter { f, m -> !m.skip_filter }
    def bypass_filter = ch_after_trim.filter { f, m -> m.skip_filter }

    MERGE_BEFORE_FILTER(to_filter)
    def ch_to_filter_merged = MERGE_BEFORE_FILTER.out.merged_tuples

    def ch_functional_filter_out
    def ch_ff_report
    def ch_ff_rejected
    def ch_ff_trimmed_to_stop
    if (functional_filter_method == "ELLPACA") {
        FUNCTIONAL_FILTER(ch_to_filter_merged)
        ch_functional_filter_out = FUNCTIONAL_FILTER.out.filtered_tuples
        ch_ff_report = FUNCTIONAL_FILTER.out.report
        ch_ff_rejected = FUNCTIONAL_FILTER.out.rejected_records
        ch_ff_trimmed_to_stop = channel.empty()
    }
    else if (functional_filter_method == "LENGTH_BASED_FILTERING") {
        LENGTH_BASED_FILTERING(ch_to_filter_merged, use_kmer_filtering)
        // The subworkflow resolves internally which stage's output is final
        // (kmer if enabled, since it runs after length filtering; length otherwise).
        ch_functional_filter_out = LENGTH_BASED_FILTERING.out.filtered_tuples
        ch_ff_report = LENGTH_BASED_FILTERING.out.filter_reports
        ch_ff_rejected = LENGTH_BASED_FILTERING.out.rejected_records
        ch_ff_trimmed_to_stop = LENGTH_BASED_FILTERING.out.trimmed_to_stop_nt
    }
    else {
        error("Functional filter method not recognized: ${functional_filter_method}")
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // MERGE BEFORE ALIGNMENT: filtered group fastas + skip-filter members,
    // reunited per group into a single fasta.
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MERGE_BEFORE_ALIGN(ch_functional_filter_out.mix(bypass_filter))
    def ch_pre_alignment_input = MERGE_BEFORE_ALIGN.out.merged_tuples

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // TRANSLATE - COLLAPSE - ADD REF (OPTIONAL)
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRE_ALIGNMENT_PROCESSING(
        ch_pre_alignment_input,
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
    sample_tuples_filter_passed_nt = ch_functional_filter_out
}
