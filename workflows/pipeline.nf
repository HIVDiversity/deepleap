nextflow.enable.dsl=2

import groovy.json.JsonSlurper
import org.apache.groovy.json.internal.LazyMap

include {CODON_ALIGNMENT} from "../subworkflows/local/alignment/main"
// include {ALIGNER_COMPARISON} from "../subworkflows/local/alignment_scoring/main"
// include {PARSE_INPUT} from "../subworkflows/local/parse_input"
include {MAFFT_ADD_PROFILE} from "../modules/local/mafft/main"

include {parseSampleSheet} from "../bin/utils"

include {PREPROCESS} from "../subworkflows/local/preprocessing/main"
include {FILTER} from "../subworkflows/local/filter/main"
include {REVERSE_TRANSLATE} from "../modules/local/reverse-translate/main"
include {REVERSE_TRANSLATE as REVERSE_TRANSLATE_PROFILE} from "../modules/local/reverse-translate/main"

include {COLLAPSE} from "../modules/local/collapse_expand_fasta/main.nf"
include {COLLAPSE as COLLAPSE_REVERSED_SEQS} from "../modules/local/collapse_expand_fasta/main.nf"

workflow HIV_SEQ_PIPELINE{
    
    
    def samplesheet = file(params.samplesheet)
    def sample_tuples = parseSampleSheet(samplesheet)


    def ch_input_files = channel.fromList(sample_tuples)
    def ch_genbank_file = channel.value(params.genbank_file)

    // Runs AGA and discards "non-functional" sequences
    FILTER(
        ch_input_files, // tuple(file, meta)
        ch_genbank_file
    )

    // Collapses the identical sequences
    COLLAPSE(
        FILTER.out.filtered_aga_output,
        channel.value("ENV_AA"),
        channel.value(true) // do strip the gaps
    )
    
    // Runs MAFFT 
    CODON_ALIGNMENT(
        COLLAPSE.out.sample_tuple,
        COLLAPSE.out.namefile_tuple
    )

    // Reverse translate the individual MAFFT alignments
    // Important to note is that we want to join three channels, but need to reorder their contents
    // CODON_ALIGNMENT -> (path, meta)
    // FILTER.out.aga_nt_alignments -> (path, meta)
    // namefile_tuple -> (path, meta)
    // After joining CODON_ALIGNMENT and nt_alignments: (meta, path, path)
    // So we need to rearrange the namefile_tuple to have (meta, path)
    REVERSE_TRANSLATE(
        CODON_ALIGNMENT.out
            .join(FILTER.out.aga_nt_alignments, by: 1)
            .join(COLLAPSE.out.namefile_tuple
                .map{it -> [it[1], it[0]]})

    )

    // Collapse the resulting NT alignments (since rev translate inadvertently expands them)
     COLLAPSE_REVERSED_SEQS(
        REVERSE_TRANSLATE.out.sample_tuple
        channel.value("ENV_NT"),
        channel.value(false) // don't strip the gaps
    )

    // Align the different profiles in nt space. 
    MAFFT_ADD_PROFILE(
        CODON_ALIGNMENT.out.toSortedList { a, b -> a[1].visit_id <=> b[1].visit_id }
            .flatten()
            .collate(2)
            .map{it[0]}
            .collect()
            .view()

    )

    // Reverse translate the profile alignment

    // REVERSE_TRANSLATE_PROFILE(
    //     MAFFT_ADD_PROFILE.out.fasta.map{it: [ [sample_id:"None"], it]}
    // )

    emit:
    // final_alignment = REVERSE_TRANSLATE_PROFILE.out.sample_tuple
    final_alignment = REVERSE_TRANSLATE.out.sample_tuple


  

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



