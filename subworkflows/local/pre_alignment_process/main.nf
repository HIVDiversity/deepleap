include { TRANSLATE } from "../../../modules/local/pipeline-utils-rs/translate/main"
include { COLLAPSE } from "../../../modules/local/collapse_expand_fasta/collapse/main"

workflow PRE_ALIGNMENT_PROCESSING {
    take:
    nt_sample_tuple // file(FASTA_NT_FILTERED), meta 

    main:

    TRANSLATE(
        nt_sample_tuple
    )

    COLLAPSE(
        TRANSLATE.out.sample_tuple
    )

    emit:
    translated_collapsed_tuples = COLLAPSE.out.sample_tuple
    namefile_tuples = COLLAPSE.out.namefile_tuple
}
