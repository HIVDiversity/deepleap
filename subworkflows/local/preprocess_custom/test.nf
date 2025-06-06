include { PREPROCESS_CUSTOM } from './main.nf'
workflow {
    def original_seqs = file("/home/dlejeune/masters/nf-test-data/test_custom_preprocess/CAP344_2000-pool1_nicd.fasta")
    def reference = file("/home/dlejeune/masters/nf-test-data/test_custom_preprocess/hxb2.fasta")

    def meta = ["sample_id": "CAP344_2000-pool1_nicd"]

    def sample_channel = channel.from([[original_seqs, meta]])
    def ref_channel = channel.of(reference)

    PREPROCESS_CUSTOM(
        sample_channel,
        ref_channel,
        true,
    )
}
