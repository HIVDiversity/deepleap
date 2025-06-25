#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-codon-alignment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/dlejeune/nf-codon-alignment
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2


include { validateParameters ; paramsSummaryLog ; samplesheetToList } from 'plugin/nf-schema'
// include {getWorkflowVersion} from './subworkflows/nf-core/utils_nextflow_pipeline/main'
include { parseSampleSheet } from "bin/utils"
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES AND SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//  include { INITIALISE          } from './subworkflows/local/initialise'

include { EXTRACT_SEQ_FROM_GB } from 'modules/local/pipeline_utils_rs/extract_seq_from_genbank/main'
include { HIV_SEQ_PIPELINE } from './workflows/pipeline'
include { PREPROCESS_AGA } from "subworkflows/local/preprocess_aga/main"
include { PREPROCESS_CUSTOM } from "subworkflows/local/preprocess_custom/main"
include { FILTER_FUNCTIONAL_SEQUENCES } from "subworkflows/local/functional_filter/main"
include { PRE_ALIGNMENT_PROCESSING } from "subworkflows/local/pre_alignment_process/main"
include { ALIGN } from "subworkflows/local/align/main"
include { POST_ALIGNMENT_PROCESS } from "subworkflows/local/post_alignment_process/main"
include { MULTI_TIMEPOINT_ALIGNMENT } from "subworkflows/local/multi_timepoint_alignment/main"




/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOW FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow MAIN_WORKFLOW {
    take:
    ch_input_files
    ch_reference_file
    ch_refToAdd
    preprocessing_type
    add_ref_before_align
    add_ref_after_align
    multi_timepoint_alignment

    main:

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // SEQUENCE TRIMMING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    if (preprocessing_type == "AGA") {
        PREPROCESS_AGA(
            ch_input_files,
            ch_reference_file,
        )

        preprocessed_files_nt = PREPROCESS_AGA.out.preprocessed_nt_seqs
    }
    else if (preprocessing_type == "CUSTOM") {
        PREPROCESS_CUSTOM(
            ch_input_files,
            ch_reference_file,
            params.use_kmer_trimming,
        )

        preprocessed_files_nt = PREPROCESS_CUSTOM.out.preprocessed_nt_seqs
    }
    else {
        println("Preprocessing type not reconized.")
        exit(1)
    }
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // FUNCTIONAL FILTERING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    // TODO - Strip illegal characters from the pre-processing?

    FILTER_FUNCTIONAL_SEQUENCES(
        preprocessed_files_nt
    )

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // TRANSLATE - COLLAPSE 
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    PRE_ALIGNMENT_PROCESSING(
        FILTER_FUNCTIONAL_SEQUENCES.out.filtered_samples,
        add_ref_before_align,
        ch_refToAdd,
    )

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // ALIGN
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ALIGN(
        PRE_ALIGNMENT_PROCESSING.out.translated_collapsed_tuples
    )

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // POSTPROCESSING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    POST_ALIGNMENT_PROCESS(
        ALIGN.out.aligned_tuple,
        PRE_ALIGNMENT_PROCESSING.out.namefile_tuples,
        PRE_ALIGNMENT_PROCESSING.out.nucleotide_files,
        add_ref_after_align,
        ch_refToAdd,
    )

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // MULTI-TIMEPOINT PROCESSING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



    if (multi_timepoint_alignment) {
        MULTI_TIMEPOINT_ALIGNMENT(
            ALIGN.out.aligned_tuple,
            FILTER_FUNCTIONAL_SEQUENCES.out.filtered_samples,
            PRE_ALIGNMENT_PROCESSING.out.namefile_tuples,
        )
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow {
    // Print parameter summary log to screen before running
    // log.info("${workflow.manifest.name} ${getWorkflowVersion()}")
    validateParameters()
    log.info(paramsSummaryLog(workflow))

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Pipeline Setup - make sure all the params are here
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // TODO: I don't think this is necessary since we have params checking from the validation pipeline
    if (!params.region_of_interest) {
        println("No regions of interest provided. Exiting.")
        exit(1)
    }

    if (!params.sample_base_dir) {
        println("No sample base directory specified. Exiting")
        exit(1)
    }

    regionShorthand = params.region_shorthand

    // If the region shorthand isn't provided, we set it to the uppercase of the first three letters of the region of interest
    if (!regionShorthand) {
        regionShorthand = params.region_of_interest[0..2].toUpperCase()
    }

    sampleBaseDir = file(params.sample_base_dir)
    regionOfInterest = params.region_of_interest
    preprocessing_type = params.preprocess
    multi_timepoint_alignment = params.multi_timepoint_alignment

    // This allow for flexibility - we can add some information to the metadata dictionary from the 
    // pipeline params
    additionalMetadata = [
        "region_of_interest": regionOfInterest
    ]

    // Set up options for adding the reference to the sequences before alignment 
    add_ref_before_align = params.add_reference_to_sequences == "BEFORE"
    add_ref_after_align = params.add_reference_to_sequences == "AFTER"

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // REFERENCE SEQUENCE CONVERSION AND PARSING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    // We need to check if the user wants to add a different reference to the sequences 
    reference_to_add = params.reference_to_add

    if (!reference_to_add) {
        reference_to_add = params.reference_file
    }


    ref_to_add_is_genbank = file(reference_to_add).extension == "gb"

    (genbank_ref, fasta_ref) = ref_to_add_is_genbank ? [channel.of(reference_to_add), channel.empty()] : [channel.empty(), channel.of(reference_to_add)]

    EXTRACT_SEQ_FROM_GB(
        genbank_ref,
        regionOfInterest,
    )

    ref_seq_name = ""

    if (ref_to_add_is_genbank) {
        ref_seq_name = regionOfInterest
    }
    else {
        ref_seq_name = file(reference_to_add).text.split("\n").find { line -> line.startsWith('>') }.substring(1)
    }

    additionalMetadata.put("ref_seq_name", ref_seq_name)

    ref_meta_dict = ["sample_id": ref_seq_name, "num_seqs": 1]
    ch_refToAdd = EXTRACT_SEQ_FROM_GB.out.extracted_sequence_fasta.mix(fasta_ref).map { ref -> [ref, ref_meta_dict] }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // BUILD SAMPLESHEET
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    samplesheet = file(params.samplesheet)
    sample_tuples = parseSampleSheet(samplesheet, sampleBaseDir, additionalMetadata)


    ch_input_files = channel.fromList(sample_tuples)
    ch_reference_file = channel.value(params.reference_file)

    MAIN_WORKFLOW(
        ch_input_files,
        ch_reference_file,
        ch_refToAdd,
        preprocessing_type,
        add_ref_before_align,
        add_ref_after_align,
        multi_timepoint_alignment,
    )
}
