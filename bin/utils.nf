def parseSampleSheet(Path samplesheet, Path sampleDir, otherMetadata){
    def output_list = []

    samplesheet.splitCsv(header: true).each{entry ->
        def new_output = []
        
        // Check if the user provided a path for this sample
        // TODO: We could add some redundancy to check if the file extension is .fa rather than .fasta

        def filename = entry.remove("filename")
        def samplePath = sampleDir.resolve(filename)
        
        new_output.add(file(samplePath))
        entry = entry + otherMetadata
        new_output.add(entry)
        
        
        output_list.add(new_output)
        
    }

    return output_list
}