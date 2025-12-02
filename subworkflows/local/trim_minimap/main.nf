include { MINIMAP_TWO } from '../../../modules/local/minimap2/main.nf'
include { TRIM_SAM } from '../../../modules/local/pipeline_utils_rs/trim_sam/main.nf'
workflow TRIM_MINIMAP {
    take:
    sample_tuple // path(input), val(meta)
    reference // File
    coords // Tuple(from, to)

    main:

    MINIMAP_TWO(
        sample_tuple,
        reference,
    )

    TRIM_SAM(
        MINIMAP_TWO.out.mapped_tuple,
        coords,
    )

    emit:
    preprocessed_nt_seqs = TRIM_SAM.out.trimmed_fasta // tuple(FASTA_NT, META)
}
