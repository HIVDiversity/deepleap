
include {AGA} from "../../../modules/local/aga/main"
include {FILTER_AGA_OUTPUT} from "../../../modules/local/filter_aga/main"
include {STRIP} from "../../../modules/local/strip/main"
include {AGA_SIEVE} from "../../../modules/local/aga_output_sieve/main"
include {SEQTK_SUBSEQ} from "../../../modules/local/seqtk/subseq/main"

workflow FILTER{
    take:
    sample_tuple // path(input), val(meta)
    genbankFile // File
    regionsOfInterest // list(String)

    main:

    AGA(
        sample_tuple,
        genbankFile

    )

    //  AGA.out.aa_alignment.view()
    
    // Since AGA produces multiple files, we need to split to each have their own meta and report files.
    def aaSeqsOfInterest = AGA
                            .out
                            .aa_alignment
                            .collect()
                            .map {splitRegionFilesToLists(it)}
                            .filter {it[2].region == "envelope-polyprotein"} // Hardcoded, but we can change

    // aaSeqsOfInterest.view()

    def ntSeqsOfInterest = AGA
                            .out
                            .nt_alignment
                            .collect()
                            .flatMap {splitRegionFilesToLists(it)}
                            .filter {it[2].region == "envelope-polyprotein"} // Hardcoded, but we can change
    
    
    // aaSeqsOfInterest.view()
    // We now extract only the reports, since we don't need to pass the files into the filtering function.
    def reports = aaSeqsOfInterest
                    .map{[it[1], it[2]]}
    
    def seqsOnly = aaSeqsOfInterest
                    .map{[it[0], it[2]]}
    // reports.view()
    // Now we need to get the names of the sequences that pass our filters
    AGA_SIEVE(
        reports
    )

    // Next we join the output of the sieve with the files again
    def seqsWithListToKeep = seqsOnly
                                .join(AGA_SIEVE.out.names_to_keep, by:1)
                                .map {[it[1],it[2],it[0]]}  // This is necessary since we need to transform from [meta, path, path] to [path, path, meta]


    SEQTK_SUBSEQ(
        seqsWithListToKeep
    )

    // AGA_SIEVE.names_to_keep

    STRIP(
        SEQTK_SUBSEQ.out.filtered_tuples,
        channel.value(".") // We want to remove any dots from the alignments.
    )

    emit:
    filtered_aga_output = STRIP.out.sample_tuple
    aga_nt_alignments = ntSeqsOfInterest

}



List splitRegionFilesToLists(List input){
    outputList = []
    
    files = input[0].clone()
    report = input[1]
    meta_dict = input[2].clone()
    
    for (file in files){
        // TODO: this is dangerous since it depends on the filename being correctly formatted. We could look at using a "contains" check for all the provided regions
        splitName = file.name.split("\\.")[0].split("_")
        region = splitName[-1]
        seqType = "UNKNOWN"
        regionType = "UNKNOWN"
        
        if (file.name.contains("_NT_")){
            seqType = "NT"
        }else if (file.name.contains("_AA_")){
            seqType = "AA"
        }

        if (file.name.contains("_PROT_")){
            regionType = "PROT"
        }else if (file.name.contains("_CDS_")){
            regionType = "CDS"
        }
    
        newMetaDict = [*:meta_dict]
        newMetaDict["region"] = region
        newMetaDict["seq_type"] = seqType
        newMetaDict["region_type"] = regionType

        newList = [file, report, newMetaDict]
        outputList.add(newList)

        println "New List:"
        println newList
    }

    println "outputList:"
    println outputList
    
    return outputList
}
