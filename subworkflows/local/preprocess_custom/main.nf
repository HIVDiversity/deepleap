include { GET_CONSENSUS } from "../../../modules/local/pipeline_utils_rs/consensus/main"
include { PAIRWISE_ALIGN_TRIM } from '../../../modules/local/pipeline_utils_rs/align_trim/main'
include { TRIM_SEQUENCES } from '../../../modules/local/pipeline_utils_rs/trim_sequences/main'
include { MAFFT_FAST_ALIGN } from '../../../modules/local/mafft/main'

workflow PREPROCESS_CUSTOM {
    take:
    sample_tuples // path(file), val(meta)
    reference_ch // File
    use_pair_aln_for_seq // boolean 

    main:

    // Make a quick alignment of the input sequences
    MAFFT_FAST_ALIGN(
        sample_tuples
    )

    // Get the consensus sequence from that alignment
    GET_CONSENSUS(
        MAFFT_FAST_ALIGN.out.sample_tuple
    )

    // Align the consensus sequence to the reference sequence
    PAIRWISE_ALIGN_TRIM(
        GET_CONSENSUS.out.sample_tuple,
        reference_ch,
        "VERBOSE",
    )

    // Create a channel that has the unaligned samples and the aligned consensus sequence
    seqsWithConsensus = sample_tuples.join(PAIRWISE_ALIGN_TRIM.out.sample_tuple, by: 1).map { [it[1], it[2], it[0]] }

    def preprocessed_sequences = channel.empty()
    if (use_pair_aln_for_seq) {
    }
    else {
        TRIM_SEQUENCES(
            seqsWithConsensus
        )

        preprocessed_sequences = TRIM_SEQUENCES.out.sample_tuple
    }

    emit:
    preprocessed_nt_seqs = TRIM_SEQUENCES.out.sample_tuple
}
