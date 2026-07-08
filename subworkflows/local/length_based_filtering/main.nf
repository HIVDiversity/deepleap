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

    def kmer_filtered_sequences
    def kmer_rejected_sequences
    def kmer_report

    if (kmer_filtering_params["use_kmer_filtering"]) {
        FILTER_BY_KMER(
            FILTER_LENGTH.out.filtered_tuples,
            channel.value(kmer_filtering_params["start_kmers"]),
            channel.value(kmer_filtering_params["end_kmers"]),
        )
        kmer_filtered_sequences = FILTER_BY_KMER.out.filtered_tuples
        kmer_rejected_sequences = FILTER_BY_KMER.out.rejected_records
        kmer_report = FILTER_BY_KMER.out.report
    }
    else {
        kmer_filtered_sequences = channel.empty()
        kmer_rejected_sequences = channel.empty()
        kmer_report = channel.empty()
    }

    emit:
    trimmed_to_stop_nt = TRIM_TO_STOP.out.trimmed_fasta // tuple(FASTA_NT, META)
    length_filtered_tuples = FILTER_LENGTH.out.filtered_tuples // tuple(FASTA_NT, META)
    kmer_filtered_tuples = kmer_filtered_sequences // tuple(FASTA_NT, META)
    length_rejected_records = FILTER_LENGTH.out.rejected_records // tuple(FASTA_NT, META)
    kmer_rejected_records = kmer_rejected_sequences // tuple(FASTA_NT, META)
    length_filter_report = FILTER_LENGTH.out.report // tuple(CSV, META)
    kmer_filter_report = kmer_report // tuple(CSV, META)
}
