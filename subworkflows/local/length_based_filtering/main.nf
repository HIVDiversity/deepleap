include { TRIM_TO_STOP } from '../../../modules/local/pipeline_utils_rs/trim_to_stop/main.nf'
include { FILTER_LENGTH } from '../../../modules/local/pipeline_utils_rs/filter_length/main.nf'
include { FILTER_BY_KMER } from '../../../modules/local/pipeline_utils_rs/filter_kmer/main.nf'

workflow LENGTH_BASED_FILTERING {
    take:
    sample_tuple // path(input), val(meta)
    start_kmers //val
    end_kmers //val

    main:

    TRIM_TO_STOP(sample_tuple)

    FILTER_LENGTH(TRIM_TO_STOP.out.trimmed_fasta)

    FILTER_BY_KMER(FILTER_LENGTH.out.filtered_tuples, start_kmers, end_kmers)

    emit:
    trimmed_to_stop_nt = TRIM_TO_STOP.out.trimmed_fasta // tuple(FASTA_NT, META)
    length_filtered_tuples = FILTER_LENGTH.out.filtered_tuples // tuple(FASTA_NT, META)
    kmer_filtered_tuples = FILTER_BY_KMER.out.filtered_tuples // tuple(FASTA_NT, META)
    length_rejected_records = FILTER_LENGTH.out.rejected_records // tuple(FASTA_NT, META)
    kmer_rejected_records = FILTER_BY_KMER.out.rejected_records // tuple(FASTA_NT, META)
    length_filter_report = FILTER_LENGTH.out.report // tuple(CSV, META)
    kmer_filter_report = FILTER_LENGTH.out.report // tuple(CSV, META)
}
