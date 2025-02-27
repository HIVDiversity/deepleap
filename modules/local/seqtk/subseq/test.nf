include {SEQTK_SUBSEQ} from "./main"

workflow{    
    def names = file("/home/dlejeune/masters/aga_util/test/names.txt")
    def seqs = file("/home/dlejeune/Documents/aga_test/outputs/proteins/DLJ_TEST_PROT_AA_env.fasta")

    meta = [
        sample_id: "CAP001_1000",
        region: "env",
        region_type: "PROT",
        seq_type: "AA"


    ]

    file_ch = channel.of([seqs,names, meta])

    SEQTK_SUBSEQ(
        file_ch
    )

}