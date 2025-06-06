include { GET_CONSENSUS } from "../../../modules/local/pipeline_utils_rs/consensus/main"
include { TRIM_CONSENSUS } from '../../../modules/local/pipeline_utils_rs/trim_consensus/main'
include { TRIM_SEQUENCES } from '../../../modules/local/pipeline_utils_rs/trim_sequences/main'
include { MAFFT_FAST_ALIGN } from '../../../modules/local/mafft/main'

workflow PREPROCESS_CUSTOM {
    take:
    sample_tuples // path(file), val(meta)
    reference_ch // File

    main:

    MAFFT_FAST_ALIGN(
        sample_tuples
    )

    GET_CONSENSUS(
        MAFFT_FAST_ALIGN.out.sample_tuple
    )

    TRIM_CONSENSUS(
        GET_CONSENSUS.out.sample_tuple,
        reference_ch,
        "VERBOSE",
    )

    seqsWithConsensus = sample_tuples.join(TRIM_CONSENSUS.out.sample_tuple, by: 1).map { [it[1], it[2], it[0]] }

    TRIM_SEQUENCES(
        seqsWithConsensus
    )

    emit:
    preprocessed_nt_seqs = TRIM_SEQUENCES.out.sample_tuple
}
