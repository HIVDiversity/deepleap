include { AGA } from './main'
workflow {

    def inFile = file("/home/dlejeune/masters/nf-test-data/aga_tests/input_b.fasta")
    def genbankFile = file("/home/dlejeune/Documents/real_data/CAP257/aga/hxb2_annotated.gb")


    def genbankChannel = channel.value(genbankFile)

    def meta = [
        sample_id: "CAP_TEST",
        cds_name: "7_envelope_polyprotein",
    ]

    def inputChannel = channel.fromList([[inFile, meta]])

    AGA(
        inputChannel,
        genbankChannel,
    )
}
