include { MAFFT } from "../../modules/local/mafft/main"
include { MAFFT_SEED } from "../../modules/local/mafft/main"
include { MUSCLE } from "../../modules/local/muscle/main"
include { MUSCLE_SUPER_FIVE } from "../../modules/local/muscle/main"
include { PROBCONS } from "../../modules/local/probcons/main"
include { TCOFFEE } from "../../modules/local/tcoffee/main"
include { REGRESSIVE_TCOFFEE } from "../../modules/local/tcoffee/main"
include { PRANK } from "../../modules/local/prank/main"
include { PAGAN } from "../../modules/local/pagan/main"
include { CLUSTAL_OMEGA } from "../../modules/local/clustal/omega/main"
include { CLUSTALW } from "../../modules/local/clustal/w/main"
include { VIRULIGN } from "../../modules/local/virulign/main"
include { MACSE } from "../../modules/local/macse/main"
include { VIRALMSA } from "../../modules/local/viralmsa/main"

workflow ALIGN {
    take:
    sample_tuple // FASTA, META
    reference // value channel
    aligner // value, str 

    main:



    if (aligner == "MAFFT") {
        MAFFT(
            sample_tuple
        )

        alignment_output_ch = MAFFT.out.sample_tuple
    }
    else if (aligner == "MAFFT-SEED") {
        MAFFT_SEED(
            sample_tuple,
            reference,
        )

        alignment_output_ch = MAFFT_SEED.out.sample_tuple
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
    else if (aligner == "PAGAN") {
        PAGAN(
            sample_tuple
        )

        alignment_output_ch = PAGAN.out.sample_tuple
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
    else if (aligner == "VIRULIGN") {
        VIRULIGN(
            sample_tuple,
            reference,
        )

        alignment_output_ch = VIRULIGN.out.sample_tuple
    }
    else if (aligner == "MACSE") {
        MACSE(
            sample_tuple
        )

        alignment_output_ch = MACSE.out.sample_tuple
    }
    else if (aligner == "VIRALMSA") {
        VIRALMSA(
            sample_tuple,
            reference,
        )

        alignment_output_ch = VIRALMSA.out.sample_tuple
    }
    else {
        alignment_output_ch = sample_tuple
    }

    emit:
    aligned_tuple = alignment_output_ch
}
