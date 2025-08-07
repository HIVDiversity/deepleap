include { MAFFT } from "../../modules/local/mafft/main"
include { MUSCLE } from "../../modules/local/muscle/main"
include { MUSCLE_SUPER_FIVE } from "../../modules/local/muscle/main"
include { PROBCONS } from "../../modules/local/probcons/main"
include { TCOFFEE } from "../../modules/local/tcoffee/main"
include { REGRESSIVE_TCOFFEE } from "../../modules/local/tcoffee/main"
include { PRANK } from "../../modules/local/prank/main"
include { CLUSTAL_OMEGA } from "../../modules/local/clustal/omega/main"
include { CLUSTALW } from "../../modules/local/clustal/w/main"

workflow ALIGN {
    take:
    sample_tuple // FASTA, META

    main:

    def aligner = params.aligner.toUpperCase()

    if (aligner == "MAFFT") {
        MAFFT(
            sample_tuple
        )

        alignment_output_ch = MAFFT.out.sample_tuple
    }
    else if (aligner == "MUSCLE") {
        MUSCLE(
            sample_tuple
        )

        alignment_output_ch = MUSCLE.out.sample_tuple
    }
    else if (aligner == "MUSCLE-FAST") {
        MUSCLE_SUPER_FIVE(
            sample_tuple
        )
        alignment_output_ch = MUSCLE_SUPER_FIVE.out.sample_tuple
    }
    else if (aligner == "PROBCONS") {
        PROBCONS(
            sample_tuple
        )

        alignment_output_ch = PROBCONS.out.sample_tuple
    }
    else if (aligner == "TCOFFEE") {
        TCOFFEE(
            sample_tuple
        )

        alignment_output_ch = TCOFFEE.out.sample_tuple
    }
    else if (aligner == "TCOFFEE_REGRESSIVE") {
        REGRESSIVE_TCOFFEE(
            sample_tuple
        )

        alignment_output_ch = REGRESSIVE_TCOFFEE.out.sample_tuple
    }
    else if (aligner == "PRANK") {
        PRANK(
            sample_tuple
        )

        alignment_output_ch = PRANK.out.sample_tuple
    }
    else if (aligner == "CLUSTAL_OMEGA") {
        CLUSTAL_OMEGA(
            sample_tuple
        )

        alignment_output_ch = CLUSTAL_OMEGA.out.sample_tuple
    }
    else if (aligner == "CLUSTALW") {
        CLUSTALW(
            sample_tuple
        )

        alignment_output_ch = CLUSTALW.out.sample_tuple
    }

    emit:
    aligned_tuple = alignment_output_ch
}
