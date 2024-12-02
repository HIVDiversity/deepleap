
include {AGA} from "../../../modules/local/aga/main"
include {FILTER_AGA_OUTPUT} from "../../../modules/local/filter_aga/main"
include {STRIP} from "../../../modules/local/strip/main"

workflow FILTER{
    take:
    sample_tuple // path(input), val(meta)
    genbankFile, // File
    regionsOfInterest, // list(String)

    main:

    AGA(
        sample_tuple,
        genbankFile

    )
    // Since AGA produces multiple files, we need to split to each have their own meta and report files.
    def aaSeqsOfInterest = AGA
                            .out
                            .aa_alignment
                            .flatMap {splitRegionFilesToLists(it)}
                            .filter({it[2].region in regionsOfInterest})
                            .filter({it[2].region_type == "PROT"}) // Hardcoded, but we can change

    def ntSeqsOfInterest = AGA
                            .out
                            .nt_alignment
                            .flatMap {splitRegionFilesToLists(it)}
                            .filter({it[2].region in regionsOfInterest})
                            .filter({it[2].region_type == "PROT"}) // Hardcoded, but we can change
    
    FILTER_AGA_OUTPUT(
        aaSeqsOfInterest
    )

    STRIP(
        FILTER_AGA_OUTPUT.out.filtered_tuples,
        channel.value(".") // We want to remove any dots from the alignments.
    )

    emit:
    filtered_aga_output = STRIP.out.sample_tuple
    aga_nt_alignments = ntSeqsOfInterest

}



List splitRegionFilesToLists(List input){
    outputList = []
    files = input[0]
    
    for (file in files){
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
    
        newMetaDict = [*:input[2]]
        newMetaDict["region"] = region
        newMetaDict["seq_type"] = seqType
        newMetaDict["region_type"] = regionType

        newList = [file, input[1], newMetaDict]
        outputList.add(newList)
    }
    
    return outputList
}
