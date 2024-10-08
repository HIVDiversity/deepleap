
include {COLLAPSE} from "../../../modules/local/collapse_expand_fasta/main.nf"
include {MAFFT} from "../../../modules/local/mafft/main.nf"
include {MAFFT_ADD} from "../../../modules/local/mafft/main.nf"
include {TRIM_TO_SEQ} from "../../../modules/local/aligment_utils/main.nf"
include {DEGAP} from "../../../modules/local/aligment_utils/main.nf"

workflow PREPROCESS{

    take:
    sample_tuple

    main:

    // MAFFT Align
    // MAFFT(
    //     sample_tuple
    // )

    // // Add the reference sequence
    // MAFFT_ADD(
    //     MAFFT.out.sample_tuple,
    //     reference_file
    // )

    // // Trim to the reference sequence
    // TRIM_TO_SEQ(
    //     MAFFT_ADD.out.sample_tuple,
    //     reference_file
    // )

    // // Degap the resulting alignment
    // DEGAP(
    //     TRIM_TO_SEQ.out.sample_tuple        
    // )

    // Collapse Identical Reads
    COLLAPSE(
        sample_tuple
    )


    emit:
    sample_tuple = COLLAPSE.out.sample_tuple
    namefile_tuple = COLLAPSE.out.namefile_tuple









}