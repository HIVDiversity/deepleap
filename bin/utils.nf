def parseSampleSheet(Path samplesheet){
    output_list = []

    for (entry in samplesheet.splitCsv(header: true)){
        def new_output = []
        new_output.add(file(entry.remove("sample_path")))
        new_output.add(entry)
        output_list.add(new_output)
    }

    return output_list
}