include {FIX_NAMES} from "./main"

workflow{

     def incorrect_names_file = file("/home/dlejeune/masters/nf-test-data/test_rename/input_file.fasta")
    

    def meta = [
        sample_id: "CAP001_2000"
    ]

    def input_channel = channel.fromList([[incorrect_names_file, meta]])

    FIX_NAMES(
        input_channel
    )
}