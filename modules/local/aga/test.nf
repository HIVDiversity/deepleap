
include { AGA } from './main'
workflow  {

    def inFile = "/home/dlejeune/Documents/real_data/CAP257/CAP257_2000_concat.fasta"
    def genbankFile = file("/home/dlejeune/Documents/real_data/CAP257/aga/hxb2_annotated.gb")

    def inputChannel = channel.fromPath(inFile).splitFasta(by: 1, limit: 5, record: [id: true, seqString: true])
    def genbankChannel = channel.value(genbankFile)

    AGA(
        inputChannel,
        genbankChannel
    )

   


        
}