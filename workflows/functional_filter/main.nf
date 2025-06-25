include { FUNCTIONAL_FILTER } from "../../../modules/local/functional_filter/main"

workflow FILTER_FUNCTIONAL_SEQUENCES {
    take:
    sample_tuple // path(FASTA_NT), dict(meta)

    main:

    FUNCTIONAL_FILTER(
        sample_tuple
    )

    emit:
    filtered_samples = FUNCTIONAL_FILTER.out.filtered_tuples
    rejected_samples = FUNCTIONAL_FILTER.out.rejected_records
    report = FUNCTIONAL_FILTER.out.report
}
