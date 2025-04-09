include {GET_CONSENSUS} from "../../../modules/local/preprocessing/consensus/main"
include { TRIM_CONSENSUS } from '../../../modules/local/preprocessing/trim_consensus/main.nf'
include { TRIM_SEQUENCES } from '../../../modules/local/preprocessing/trim_sequences/main.nf'

workflow PREPROCESS_CUSTOM{

    take:
    sample_tuples // path(file), val(meta)
    reference_ch // File
    
    main:
    
    GET_CONSENSUS(
        sample_tuples
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
    processed_aa_seqs = TRIM_SEQUENCES.out.sample_tuple

    
}