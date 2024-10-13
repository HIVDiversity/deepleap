include {COLLAPSE} from "./main"

workflow{

    def input_file = file("/home/dlejeune/masters/nf-test-data/test_collapse/input_seqs.fasta")

    meta = [
        sample_id: "CAP001_1000"
    ]

    file_ch = channel.of([input_file, meta])

    COLLAPSE(
        file_ch
    )
    



}