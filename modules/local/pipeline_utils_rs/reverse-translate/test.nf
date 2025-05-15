include { REVERSE_TRANSLATE } from "./main"

workflow {

    def aa_file = file("/home/dlejeune/masters/nf-test-data/test_rev_trn/aa_aligned_seqs.fasta")
    def nt_file = file("/home/dlejeune/masters/nf-test-data/test_rev_trn/nt_seqs.fasta")

    def meta = [
        sample_id: "TEST001"
    ]

    def input_channel = channel.fromList([[aa_file, nt_file, meta]])

    REVERSE_TRANSLATE(
        input_channel
    )

    REVERSE_TRANSLATE.out.sample_tuple.view()
}
