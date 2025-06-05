include { EXPAND } from "../../../modules/local/collapse_expand_fasta/expand/main"
include { REVERSE_TRANSLATE } from "../../../modules/local/pipeline_utils_rs/reverse-translate/main"
include { MAFFT_ADD } from "../../../modules/local/mafft/main"

workflow POST_ALIGNMENT_PROCESS {
    take:
    aligned_tuples
    namefile_tuples
    nt_tuples
    add_ref_seq
    reference

    main:
    def samples = aligned_tuples
    if (add_ref_seq) {
        MAFFT_ADD(
            aligned_tuples,
            reference,
        )
        samples = MAFFT_ADD.out.sample_tuple
    }

    // Need to reorganise this from meta,sequence,namefile to sequence,namefile,meta
    def sequence_and_namefiles = samples
        .join(namefile_tuples, by: 1)
        .map { it -> [it[1], it[2], it[0]] }

    EXPAND(
        sequence_and_namefiles
    )

    def aa_and_nt_seqs = EXPAND.out.sample_tuple
        .join(nt_tuples, by: 1)
        .map { it -> [it[1], it[2], it[0]] }

    REVERSE_TRANSLATE(
        aa_and_nt_seqs
    )

    emit:
    revserse_translated_tuples = REVERSE_TRANSLATE.out.sample_tuple
}
