nextflow.enable.dsl = 2

include { MUSCLE } from "./main"

workflow {

    inputFile = file("/home/dlejeune/Documents/scratch/empty.fasta")

    def meta = [
        sample_id: "test_run_001"
    ]



    input_channel = channel.fromList([[inputFile, meta]])

    MUSCLE(
        input_channel
    )
}
