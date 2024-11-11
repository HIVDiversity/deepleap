nextflow.enable.dsl=2

include {MUSCLE} from "./main"

workflow{

    main:

    inputFile = file("/home/dlejeune/masters/nf-test-data/test_muscle/inputseqs.fasta")

    def meta = [
        sample_id: "test_run_001"
    ]

    

    input_channel = channel.fromList([[inputFile, meta]])

    MUSCLE(
        input_channel
    )

}