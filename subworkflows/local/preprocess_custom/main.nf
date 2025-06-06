include { GET_CONSENSUS } from "../../../modules/local/pipeline_utils_rs/consensus/main"
include { PAIRWISE_ALIGN_TRIM as PAIRWISE_ALN_TRIM_CONSENSUS } from '../../../modules/local/pipeline_utils_rs/align_trim/main'
include { PAIRWISE_ALIGN_TRIM as PAIRWISE_ALN_TRIM_SEQS } from '../../../modules/local/pipeline_utils_rs/align_trim/main'
include { KMER_TRIM_SEQUENCES } from '../../../modules/local/pipeline_utils_rs/kmer_trim/main'
include { MAFFT_FAST_ALIGN } from '../../../modules/local/mafft/main'

workflow PREPROCESS_CUSTOM {
    take:
    sample_tuples // path(file), val(meta)
    ch_reference // File
    use_kmer_trimming // boolean 

    main:

    // Make a quick alignment of the input sequences
    MAFFT_FAST_ALIGN(
        sample_tuples
    )

    // Get the consensus sequence from that alignment
    GET_CONSENSUS(
        MAFFT_FAST_ALIGN.out.sample_tuple
    )

    def ch_sampleAlnAndRef = GET_CONSENSUS.out.sample_tuple.merge(ch_reference) { consensus, reference ->
        return tuple(consensus[0], reference, consensus[1])
    }

    // Align the consensus sequence to the reference sequence
    PAIRWISE_ALN_TRIM_CONSENSUS(
        ch_sampleAlnAndRef,
        "VERBOSE",
    )

    // Create a channel that has the unaligned samples and the aligned consensus sequence
    def ch_seqsWithConsensus = sample_tuples
        .join(PAIRWISE_ALN_TRIM_CONSENSUS.out.trimmed_fasta, by: 1)
        .map { meta, samples, consensus -> [samples, consensus, meta] }

    // Trim the rest of the sequences depending on the mode specified by the user.
    def preprocessed_sequences = channel.empty()
    if (use_kmer_trimming) {
        KMER_TRIM_SEQUENCES(
            ch_seqsWithConsensus
        )

        preprocessed_sequences = KMER_TRIM_SEQUENCES.out.sample_tuple
    }
    else {
        PAIRWISE_ALN_TRIM_SEQS(
            ch_seqsWithConsensus,
            "INFO",
        )
        preprocessed_sequences = PAIRWISE_ALN_TRIM_SEQS.out.trimmed_fasta
    }

    emit:
    preprocessed_nt_seqs = preprocessed_sequences
}
