include {GET_CONSENSUS} from "../../../modules/local/preprocessing/consensus/main"
include { TRIM_CONSENSUS } from '../../../modules/local/preprocessing/trim_consensus/main.nf'
include { TRIM_SEQUENCES } from '../../../modules/local/preprocessing/trim_sequences/main.nf'
include { MAFFT_FAST_ALIGN } from '../../../modules/local/mafft/main.nf'

workflow PREPROCESS_CUSTOM{

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
        reference_ch
    )

    seqsWithConsensus = sample_tuples.join(TRIM_CONSENSUS.out.sample_tuple, by:1).map {[it[1], it[2], it[0]]}

    TRIM_SEQUENCES(
        seqsWithConsensus
    )

    emit:
    preprocessed_nt_seqs = TRIM_SEQUENCES.out.sample_tuple

    
}