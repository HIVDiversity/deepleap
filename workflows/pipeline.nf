nextflow.enable.dsl=2

import groovy.json.JsonSlurper
import org.apache.groovy.json.internal.LazyMap

include {CODON_ALIGNMENT} from "../subworkflows/local/alignment/main"
// include {ALIGNER_COMPARISON} from "../subworkflows/local/alignment_scoring/main"
// include {PARSE_INPUT} from "../subworkflows/local/parse_input"
include {MAFFT_ADD_PROFILE} from "../modules/local/mafft/main"

include {parseSampleSheet} from "../bin/utils"

include {PREPROCESS} from "../subworkflows/local/preprocessing/main"

workflow HIV_SEQ_PIPELINE{
    
    
    // runList = parseInputConfig(params.config_file)
    
    // runChannel = channel.fromList(runList)


    // configChannel = channel.fromPath(params.config_file)

    // runList = PARSE_INPUT(configChannel).runs
    
    // ALIGNER_COMPARISON(runList)  

    
    
    def base_sample_dir = "/home/dlejeune/Documents/real_data/do_dump/pools"
    def cap_num = "CAP008"
    def file_selector =  "${base_sample_dir}/*/${cap_num}**-degapped.fasta"
    
    // def input_files = files(file_selector)
    // def ch_input_files = channel.fromList(input_files)

    
    def samplesheet = file(params.samplesheet)
    def sample_tuples = parseSampleSheet(samplesheet)


    def ch_input_files = channel.fromList(sample_tuples)
    def reference_file = channel.value(params.reference_file)

    PREPROCESS(
        ch_input_files, // tuple(file, meta)
        reference_file
    )
    
    CODON_ALIGNMENT(
        PREPROCESS.out.sample_tuple,
        PREPROCESS.out.namefile_tuple
    )

    MAFFT_ADD_PROFILE(
        CODON_ALIGNMENT.out.map{it[0]}.collect()
    )

    emit:
    final_alignment = MAFFT_ADD_PROFILE.out.fasta


  

}

def convertToMap(def obj) {
    if (obj instanceof LazyMap) {
        obj.collectEntries { key, value -> [(key): convertToMap(value)] }
    } else if (obj instanceof List) {
        obj.collect { item -> convertToMap(item) }
    } else {
        obj
    }
}


def parseInputConfig(configFile){
    def inputFile = new File(configFile.toString())
    def jsonDict = new JsonSlurper().parseText(inputFile.text)

    def tupleList = []

    for (entry in jsonDict["runs"]){
        temp_file = file(entry["meta"]["file"])
        temp_meta = convertToMap(entry)

        tupleList.add(new Tuple(temp_file, temp_meta))
    }

    return tupleList
}



