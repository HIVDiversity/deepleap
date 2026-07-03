include { TRIM_TO_STOP } from '../../../modules/local/pipeline_utils_rs/trim_to_stop/main.nf'
include { FILTER_LENGTH } from '../../../modules/local/pipeline_utils_rs/filter_length/main.nf'

workflow LENGTH_BASED_FILTERING {
    take:
    sample_tuple // path(input), val(meta)

    main:

    TRIM_TO_STOP(sample_tuple)

    FILTER_LENGTH(TRIM_TO_STOP.out.trimmed_fasta)

    emit:
    trimmed_to_stop_nt = TRIM_TO_STOP.out.trimmed_fasta // tuple(FASTA_NT, META)
    filtered_tuples = FILTER_LENGTH.out.filtered_tuples // tuple(FASTA_NT, META)
    rejected_records = FILTER_LENGTH.out.rejected_records // tuple(FASTA_NT, META)
    report = FILTER_LENGTH.out.report // tuple(CSV, META)
}
