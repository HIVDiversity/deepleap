include { TRIM_TO_STOP } from '../../../modules/local/pipeline_utils_rs/trim_to_stop/main.nf'
include { FILTER_LENGTH } from '../../../modules/local/pipeline_utils_rs/filter_length/main.nf'
include { FILTER_BY_KMER } from '../../../modules/local/pipeline_utils_rs/filter_kmer/main.nf'

workflow LENGTH_BASED_FILTERING {
    take:
    sample_tuple // path(input), val(meta)
    kmer_filtering_params // dict(use_kmer_filtering, start_kmers, send_kmers)

    main:

    TRIM_TO_STOP(sample_tuple)

    FILTER_LENGTH(TRIM_TO_STOP.out.trimmed_fasta)

    // Tag each stage's rejected/report records with meta.filter_stage so they
    // can be mixed into single channels instead of one pair of emits per stage.
    def ch_rejected_records = FILTER_LENGTH.out.rejected_records.map { f, m -> [f, m + [filter_stage: "length"]] }
    def ch_filter_reports = FILTER_LENGTH.out.report.map { f, m -> [f, m + [filter_stage: "length"]] }

    def ch_filtered_tuples

    if (kmer_filtering_params["use_kmer_filtering"]) {
        FILTER_BY_KMER(
            FILTER_LENGTH.out.filtered_tuples,
            channel.value(kmer_filtering_params["start_kmers"]),
            channel.value(kmer_filtering_params["end_kmers"]),
        )
        // Kmer filtering runs after length filtering, so its output is the
        // fully-filtered result.
        ch_filtered_tuples = FILTER_BY_KMER.out.filtered_tuples
        ch_rejected_records = ch_rejected_records.mix(FILTER_BY_KMER.out.rejected_records.map { f, m -> [f, m + [filter_stage: "kmer"]] })
        ch_filter_reports = ch_filter_reports.mix(FILTER_BY_KMER.out.report.map { f, m -> [f, m + [filter_stage: "kmer"]] })
    }
    else {
        ch_filtered_tuples = FILTER_LENGTH.out.filtered_tuples
    }

    emit:
    trimmed_to_stop_nt = TRIM_TO_STOP.out.trimmed_fasta // tuple(FASTA_NT, META)
    filtered_tuples = ch_filtered_tuples // tuple(FASTA_NT, META) - passes all active filter stages
    rejected_records = ch_rejected_records // tuple(FASTA_NT, META) - meta.filter_stage: "length"|"kmer"
    filter_reports = ch_filter_reports // tuple(CSV, META) - meta.filter_stage: "length"|"kmer"
}
