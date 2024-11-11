nextflow.enable.dsl=2

import groovy.json.JsonSlurper
import org.apache.groovy.json.internal.LazyMap


workflow PARSE_INPUT{
    take:
    samplesheet

    

    main:

    

    jsonSpec.splitJson()
        .map{it.value}
        .flatMap()
        .map{createRunTuple(it)}
        .set{runs}


    emit:
    runs




}

def process_samplesheet(File samplesheet){
    output_list = []

    for (entry in samplesheet.splitCsv(header: true)){
        def new_output = []
        new_output.add(file(entry.remove("sample_path")))
        new_output.add(entry)
        output_list.add(new_output)
    }

    return output_list

}