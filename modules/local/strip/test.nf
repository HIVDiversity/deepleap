include {STRIP} from "./main"

workflow{
    
    def input_file = file("/home/dlejeune/masters/nf-test-data/test_strip/test_strip.fasta")

    meta = [
        sample_id: "CAP001_1000"
    ]

    file_ch = channel.of([input_file, meta])
    remove_string = channel.value(".-")

    STRIP(
        file_ch,
        remove_string
    )
    
}