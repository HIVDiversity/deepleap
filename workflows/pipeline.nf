nextflow.enable.dsl = 2

include { MAFFT_ADD_PROFILE } from "../modules/local/mafft/main"
include { MAFFT } from "../modules/local/mafft/main"
include { MUSCLE } from "../modules/local/muscle/main"

include { parseSampleSheet } from "../bin/utils"

include { PREPROCESS_AGA } from "../subworkflows/local/preprocess_aga/main"
include { PREPROCESS_CUSTOM } from "../subworkflows/local/preprocess_custom/main"
include { FILTER_FUNCTIONAL_SEQUENCES } from "../subworkflows/local/functional_filter/main"
include { PRE_ALIGNMENT_PROCESSING } from "../subworkflows/local/pre_alignment_process/main"
include { ALIGN } from "../subworkflows/local/align/main"
include { POST_ALIGNMENT_PROCESS } from "../subworkflows/local/post_alignment_process/main"
include { MULTI_TIMEPOINT_ALIGNMENT } from "../subworkflows/local/multi_timepoint_alignment/main"

workflow HIV_SEQ_PIPELINE {

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Pipeline Setup - make sure all the param are here
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (!params.region_of_interest) {
        println("No regions of interest provided. Exiting.")
        exit(1)
    }

    if (!params.sample_base_dir) {
        println("No sample base directory specified. Exiting")
        exit(1)
    }

    def regionShorthand = params.region_shorthand

    // If the region shorthand isn't provided, we set it to the uppercase of the first three letters of the region of interest
    if (!regionShorthand) {
        regionShorthand = params.region_of_interest[0..2].toUpperCase()
    }

    def sampleBaseDir = file(params.sample_base_dir)
    def regionOfInterest = params.region_of_interest
    def preprocessing_type = params.preprocess
    def multi_timepoint_alignment = params.multi_timepoint_alignment

    // This allow for flexibility - we can add some information to the metadata dictionary from the 
    // pipeline params
    def additionalMetadata = [
        "region_of_interest": regionOfInterest
    ]

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // BUILD SAMPLESHEET
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def samplesheet = file(params.samplesheet)
    def sample_tuples = parseSampleSheet(samplesheet, sampleBaseDir, additionalMetadata)


    def ch_input_files = channel.fromList(sample_tuples)
    def ch_reference_file = channel.value(params.reference_file)


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // PROCESSING STARTS HERE
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
        )

        preprocessed_files_nt = PREPROCESS_CUSTOM.out.preprocessed_nt_seqs
    }
    else {
        println("Preprocessing type not reconized.")
        exit(1)
    }

    // TODO - Strip illegal characters from the pre-processing?

    FILTER_FUNCTIONAL_SEQUENCES(
        preprocessed_files_nt
    )

    PRE_ALIGNMENT_PROCESSING(
        FILTER_FUNCTIONAL_SEQUENCES.out.filtered_samples
    )

    ALIGN(
        PRE_ALIGNMENT_PROCESSING.out.translated_collapsed_tuples
    )

    POST_ALIGNMENT_PROCESS(
        ALIGN.out.aligned_tuple,
        PRE_ALIGNMENT_PROCESSING.out.namefile_tuples,
        FILTER_FUNCTIONAL_SEQUENCES.out.filtered_samples,
    )

    if (multi_timepoint_alignment) {
        MULTI_TIMEPOINT_ALIGNMENT(
            ALIGN.out.aligned_tuple,
            FILTER_FUNCTIONAL_SEQUENCES.out.filtered_samples,
            PRE_ALIGNMENT_PROCESSING.out.namefile_tuples,
        )
    }
}

def convertToMap(obj) {
    if (obj instanceof org.apache.groovy.json.internal.LazyMap) {
        obj.collectEntries { key, value -> [(key): convertToMap(value)] }
    }
    else if (obj instanceof List) {
        obj.collect { item -> convertToMap(item) }
    }
    else {
        obj
    }
}


def parseInputConfig(configFile) {
    def inputFile = new File(configFile.toString())
    def jsonDict = new groovy.json.JsonSlurper().parseText(inputFile.text)

    def tupleList = []

    jsonDict["runs"].each { entry ->

        def temp_file = file(entry["meta"]["file"])
        def temp_meta = convertToMap(entry)

        tupleList.add(new Tuple(temp_file, temp_meta))
    }

    return tupleList
}
