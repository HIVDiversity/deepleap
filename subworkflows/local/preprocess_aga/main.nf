include { AGA } from '../../../modules/local/aga/main.nf'
workflow PREPROCESS_AGA {
    take:
    sample_tuple // path(input), val(meta)
    genbankFile // File

    main:

    AGA(
        sample_tuple,
        genbankFile,
    )

    emit:
    preprocessed_nt_seqs = AGA.out.nt_alignment // tuple(FASTA_NT, META)
}
