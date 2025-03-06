nextflow.enable.dsl=2

include {MAFFT_ADD_PROFILE} from "../modules/local/mafft/main"
include {MAFFT} from "../modules/local/mafft/main"
include {MUSCLE} from "../modules/local/muscle/main"

include {parseSampleSheet} from "../bin/utils"

include {FILTER} from "../subworkflows/local/filter/main"

include {REVERSE_TRANSLATE} from "../modules/local/reverse-translate/main"
include {REVERSE_TRANSLATE as REVERSE_TRANSLATE_PROFILE} from "../modules/local/reverse-translate/main"

include {COLLAPSE as COLLAPSE_AA_SEQS} from "../modules/local/collapse_expand_fasta/main.nf"
include {COLLAPSE as COLLAPSE_REVERSED_SEQS} from "../modules/local/collapse_expand_fasta/main.nf"

workflow HIV_SEQ_PIPELINE{

    main:

        if (!params.region_of_interest){
            println "No regions of interest provided. Exiting."
            exit 1
        }



        if (!params.sample_base_dir){
            println "No sample base directory specified. Exiting"
            exit 1
        }

        def sampleBaseDir = file(params.sample_base_dir)


        def regionOfInterest = params.region_of_interest
        def regionOfInterest_ch = channel.value(regionOfInterest)

        def additionalMetadata = [
            "region_of_interest": regionOfInterest
        ]
        
        def samplesheet = file(params.samplesheet)
        def sample_tuples = parseSampleSheet(samplesheet, sampleBaseDir, additionalMetadata)


        def ch_input_files = channel.fromList(sample_tuples)
        def ch_genbank_file = channel.value(params.genbank_file)

        // Runs AGA and discards "non-functional" sequences
        FILTER(
            ch_input_files, // tuple(file, meta)
            ch_genbank_file, // file
            regionOfInterest_ch // value(list(String))
        )

        // Collapses the identical sequences
        COLLAPSE_AA_SEQS(
            FILTER.out.filtered_aga_output,
            channel.value("ENV_AA"), // FIXME: This is not good
            channel.value(true) // do strip the gaps
        )
        
        def aligner = params.aligner.toUpperCase()

        if (aligner == "MAFFT"){
            MAFFT(
                COLLAPSE_AA_SEQS.out.sample_tuple
            )

            alignment_output_ch = MAFFT.out.sample_tuple

        }else if (aligner == "MUSCLE"){
            MUSCLE(
            COLLAPSE_AA_SEQS.out.sample_tuple
            )

            alignment_output_ch = MUSCLE.out.sample_tuple

        }

        // alignment_output_ch.view() 
        // Reverse translate the individual MAFFT alignments
        // Important to note is that we want to join three channels, but need to reorder their contents
        // CODON_ALIGNMENT -> (path, meta)
        // FILTER.out.aga_nt_alignments -> (path, meta)
        // namefile_tuple -> (path, meta)
        // After joining CODON_ALIGNMENT and nt_alignments: (meta, path, path)
        // So we need to rearrange the namefile_tuple to have (meta, path)
        REVERSE_TRANSLATE(
            alignment_output_ch
                .join(FILTER.out.aga_nt_alignments, by: 1)
                .join(COLLAPSE_AA_SEQS.out.namefile_tuple
                    .map{it -> [it[1], it[0]]})

        )

        // Collapse the resulting NT alignments (since rev translate inadvertently expands them)
        COLLAPSE_REVERSED_SEQS(
            REVERSE_TRANSLATE.out.sample_tuple,
            channel.value("ENV_NT"),
            channel.value(false) // don't strip the gaps
        )

        // // We should perform a profile alignment of the Amino Acids
        // // Then we want to reverse translate that whole thing
        // MAFFT_ADD_PROFILE(
        //     MAFFT.out.sample_tuple.toSortedList { a, b -> a[1].visit_id <=> b[1].visit_id }
        //         .flatten()
        //         .collate(2)
        //         .map{it[0]}
        //         .collect()
        //         .view()

        // )

        // Reverse translate the profile alignment

        // REVERSE_TRANSLATE_PROFILE(
        //     MAFFT_ADD_PROFILE.out.fasta.map{it: [ [sample_id:"None"], it]}
        // )

    emit:
        // final_alignment = REVERSE_TRANSLATE_PROFILE.out.sample_tuple
        final_alignment = REVERSE_TRANSLATE.out.sample_tuple


  

}

def convertToMap(def obj) {
    if (obj instanceof org.apache.groovy.json.internal.LazyMap) {
        obj.collectEntries { key, value -> [(key): convertToMap(value)] }
    } else if (obj instanceof List) {
        obj.collect { item -> convertToMap(item) }
    } else {
        obj
    }
}


def parseInputConfig(configFile){
    def inputFile = new File(configFile.toString())
    def jsonDict = new groovy.json.JsonSlurper().parseText(inputFile.text)

    def tupleList = []

    jsonDict["runs"].each{entry ->

        def temp_file = file(entry["meta"]["file"])
        def temp_meta = convertToMap(entry)

        tupleList.add(new Tuple(temp_file, temp_meta))


    }

    return tupleList
}



