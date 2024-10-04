
include {REVERSE_TRANSLATE} from "./main"

workflow{

    def aa_file = file("/home/dlejeune/masters/nf-test-data/test_rev_trn/aa_aligned_seqs.fasta")
    def nt_file = file("/home/dlejeune/masters/nf-test-data/test_rev_trn/nt_seqs.fasta")

    def meta = [
        sample_id: "test_run_001"
    ]

    def input_channel = channel.fromList([[meta, aa_file, nt_file]])

    REVERSE_TRANSLATE(
        input_channel
    )

    REVERSE_TRANSLATE.out.sample_tuple.view()

}