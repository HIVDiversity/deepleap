include { EXPAND } from "../../../modules/local/collapse_expand_fasta/expand/main"
include { REVERSE_TRANSLATE } from "../../../modules/local/pipeline_utils_rs/reverse-translate/main"
include { TRANSLATE as TRANSLATE_REFERENCE } from "../../../modules/local/pipeline_utils_rs/translate/main"
include { MAFFT_ADD } from "../../../modules/local/mafft/main"
include { ADD_SEQUENCES } from "../../../modules/local/utils/add_sequences/main"

workflow POST_ALIGNMENT_PROCESS {
    take:
    aligned_tuples
    namefile_tuples
    nt_tuples
    add_ref_seq
    ch_reference

    main:
    def samples = aligned_tuples
    def nt_samples = nt_tuples
    // def ch_ref = channel.value(ch_reference)
    if (add_ref_seq) {
        TRANSLATE_REFERENCE(
            ch_reference
        )
        MAFFT_ADD(
            aligned_tuples,
            TRANSLATE_REFERENCE.out.sample_tuple.collect().map { ref_file, _meta -> ref_file },
        )
        ADD_SEQUENCES(
            nt_tuples.merge(ch_reference) { sample, ref -> tuple([sample[0], ref[0]], sample[1]) }
        )
        samples = MAFFT_ADD.out.sample_tuple
        nt_samples = ADD_SEQUENCES.out.fasta_tuple
    }

    // Need to reorganise this from meta,sequence,namefile to sequence,namefile,meta
    def sequence_and_namefiles = samples
        .join(namefile_tuples, by: 1)
        .map { it -> [it[1], it[2], it[0]] }

    EXPAND(
        sequence_and_namefiles
    )

    def aa_and_nt_seqs = EXPAND.out.sample_tuple
        .join(nt_samples, by: 1)
        .map { it -> [it[1], it[2], it[0]] }

    REVERSE_TRANSLATE(
        aa_and_nt_seqs
    )

    emit:
    reverse_translated_tuples = REVERSE_TRANSLATE.out.sample_tuple
}
