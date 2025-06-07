include { COLLAPSE } from "../../../modules/local/collapse_expand_fasta/collapse/main"
include { TRANSLATE } from "../../../modules/local/pipeline_utils_rs/translate/main"
include { TRANSLATE as TRANSLATE_REFERENCE } from "../../../modules/local/pipeline_utils_rs/translate/main"
include { ADD_SEQUENCES } from "../../../modules/local/utils/add_sequences/main"

workflow PRE_ALIGNMENT_PROCESSING {
    take:
    nt_sample_tuple // file(FASTA_NT_FILTERED), meta 
    val_addRefToSeqs // bool: indicates that a reference should be added to samples prior to alignment
    ch_reference_to_add // file: the reference that should be added

    main:

    TRANSLATE(
        nt_sample_tuple
    )

    COLLAPSE(
        TRANSLATE.out.sample_tuple
    )
    output = COLLAPSE.out.sample_tuple

    if (val_addRefToSeqs) {

        TRANSLATE_REFERENCE(
            ch_reference_to_add
        )
        ADD_SEQUENCES(
            COLLAPSE.out.sample_tuple.merge(TRANSLATE_REFERENCE.out.sample_tuple.collect()) { sample, ref ->
                tuple([sample[0], ref[0]], sample[1])
            }
        )
        output = ADD_SEQUENCES.out.fasta_tuple
    }

    emit:
    translated_collapsed_tuples = output
    namefile_tuples = COLLAPSE.out.namefile_tuple
}
