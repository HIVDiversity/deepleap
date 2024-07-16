
include {COLLAPSE} from "../../../modules/local/aligment_utils/main.nf"
include {MAFFT} from "../../../modules/local/mafft/main.nf"
include {MAFFT_ADD} from "../../../modules/local/mafft/main.nf"
include {TRIM_TO_SEQ} from "../../../modules/local/aligment_utils/main.nf"
include {DEGAP} from "../../../modules/local/aligment_utils/main.nf"

workflow PREPROCESS{

    take:
    input_sample
    reference_file

    main:

    // MAFFT Align
    MAFFT(
        input_sample
    )

    // Add the reference sequence
    MAFFT_ADD(
        MAFFT.out.fasta,
        reference_file
    )

    // Trim to the reference sequence
    TRIM_TO_SEQ(
        MAFFT_ADD.out.fasta,
        reference_file
    )

    // Degap the resulting alignment
    DEGAP(
        TRIM_TO_SEQ.out.fasta,
        reference_file
    )

    // Collapse Identical Reads
    COLLAPSE(
        DEGAP.out.fasta
    )


    emit:
    collapsed = COLLAPSE.out.samples
    collapsed_names = COLLAPSE.out.namefile










}