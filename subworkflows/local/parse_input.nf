nextflow.enable.dsl=2

import groovy.json.JsonSlurper
import org.apache.groovy.json.internal.LazyMap


workflow PARSE_INPUT{
    take:
    jsonSpec

    

    main:

    

    jsonSpec.splitJson()
        .map{it.value}
        .flatMap()
        .map{createRunTuple(it)}
        .set{runs}


    emit:
    runs




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

def createRunTuple(jsonRow){
    return [file(jsonRow["meta"]["file"]), convertToMap(jsonRow)]
}
