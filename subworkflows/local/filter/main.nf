
include {AGA} from "../../../modules/local/aga/main"
include {FILTER_AGA} from "../../../modules/local/aligment_utils/main"

workflow FILTER{
    take:
    sample_tuple // path(input), val(meta)
    genbankFile

    main:

    
    def splitReadChannel = sample_tuple.map{it[0]}.splitFasta(by: 1, record: [id: true, seqString: true])
    def sample_meta = sample_tuple.map{it[1]}

    AGA(
        splitReadChannel,
        genbankFile

    )


    def allFileChannel = channel.empty().mix(AGA.out.nt_alignment).mix(AGA.out.aa_alignment).mix(AGA.out.metrics).collect()

    FILTER_AGA(
        allFileChannel,
        sample_meta
    )

    emit:
    FILTER_AGA.out.functionalNTSeqs

}