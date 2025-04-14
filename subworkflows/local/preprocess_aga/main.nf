include { AGA } from '../../../modules/local/aga/main.nf'
workflow PREPROCESS_AGA {
    take:
    sample_tuple // path(input), val(meta)
    genbankFile // File

    main:

    AGA(
        sample_tuple,
        genbankFile
    )

    // Since AGA produces multiple files, we need to split to each have their own meta and report files.
    def aaSeqsOfInterest = AGA
                            .out
                            .aa_alignment
    
    // We want to extract only the sequences from AGA's output. At this point we don't care about the report. 
    
    def seqsOnlyNT = aaSeqsOfInterest
                    .map{[it[0], it[2]]}

    emit:
    preprocessed_nt_seqs = seqsOnlyNT // tuple(FASTA_NT, META)
    
}