#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-codon-alignment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/dlejeune/nf-codon-alignment
----------------------------------------------------------------------------------------
*/

nextflow.preview.output = true
nextflow.enable.strict = true


include { validateParameters ; paramsSummaryLog ; samplesheetToList } from 'plugin/nf-schema'
// include {getWorkflowVersion} from './subworkflows/nf-core/utils_nextflow_pipeline/main'
include { parseSampleSheet } from "./bin/utils"
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES AND SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//  include { INITIALISE          } from './subworkflows/local/initialise'

include { EXTRACT_SEQ_FROM_GB } from './modules/local/pipeline_utils_rs/extract_seq_from_genbank/main'
include { PREPROCESS } from "./workflows/preprocess/main"
include { ALIGN } from "./workflows/align/main"
include { POSTPROCESS } from "./workflows/postprocess/main"
include { MULTI_TIMEPOINT_ALIGNMENT } from "./workflows/multi_timepoint_alignment/main"




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

    PREPROCESS(
        ch_input_files,
        ch_reference_file,
        preprocessing_type,
        ch_refToAdd,
        add_ref_before_align,
    )

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // ALIGN
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ALIGN(
        PREPROCESS.out.sample_tuples_aa
    )

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // POSTPROCESSING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    POSTPROCESS(
        ALIGN.out.aligned_tuple,
        PREPROCESS.out.namefile_tuples,
        PREPROCESS.out.sample_tuples_nt,
        add_ref_after_align,
        ch_refToAdd,
    )

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // MULTI-TIMEPOINT PROCESSING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def ch_multi_timepoint_alignment = channel.empty()
    if (multi_timepoint_alignment) {
        MULTI_TIMEPOINT_ALIGNMENT(
            ALIGN.out.aligned_tuple,
            PREPROCESS.out.sample_tuples_nt,
            PREPROCESS.out.namefile_tuples,
        )

        ch_multi_timepoint_alignment = MULTI_TIMEPOINT_ALIGNMENT.out.sample_tuples_prof_aln_nt
    }

    emit:
    sample_tuples_aligned_nt = POSTPROCESS.out.reverse_translated_tuples
    sample_tuples_aligned_aa = POSTPROCESS.out.sample_tuples_aligned_aa
    functional_filter_reports = PREPROCESS.out.filter_report
    sample_tuples_prof_aln_nt = ch_multi_timepoint_alignment
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow {
    main:
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
    ch_refToAdd = EXTRACT_SEQ_FROM_GB.out.extracted_sequence_fasta.mix(fasta_ref).map { ref -> [ref, ref_meta_dict] }.collect()


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

    publish:
    sample_tuples_aligned_nt = MAIN_WORKFLOW.out.sample_tuples_aligned_nt
    sample_tuples_aligned_aa = MAIN_WORKFLOW.out.sample_tuples_aligned_aa
    functional_filter_reports = MAIN_WORKFLOW.out.functional_filter_reports
    sample_tuples_prof_aln_nt = MAIN_WORKFLOW.out.sample_tuples_prof_aln_nt
}

output {
    sample_tuples_aligned_nt {
        path { sample, meta ->
            sample >> "${params.run_name}/${meta.sample_id}/${meta.sample_id}_aligned_nt.fasta"
        }
    }
    sample_tuples_aligned_aa {
        path { sample, meta ->
            sample >> "${params.run_name}/${meta.sample_id}/${meta.sample_id}_aligned_aa.fasta"
        }
    }
    functional_filter_reports {
        path { sample, meta ->
            sample >> "${params.run_name}/${meta.sample_id}/${meta.sample_id}_filter-report.csv"
        }
    }
    sample_tuples_prof_aln_nt {
        path { sample, meta ->
            sample >> "${params.run_name}/${meta.sample_id}/${meta.sample_id}_profile-aligned_nt.fasta"
        }
    }
}
