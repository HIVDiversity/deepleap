include { PREPROCESS_AGA } from './main.nf'

workflow  {
    def original_seqs = file("/home/dlejeune/masters/nf-test-data/test_aga_preprocess/CAP344_2000-pool1_nicd.fasta")
    def genbank = file("/home/dlejeune/masters/nf-test-data/test_aga_preprocess/hxb2_annotated.gb")

    def meta = ["sample_id":"CAP344_2000-pool1_nicd", "region_of_interest": "envelope-polyprotein"]

    def sample_channel = channel.from([[original_seqs, meta]])
    def genbank_channel = channel.of(genbank)

    PREPROCESS_AGA(
        sample_channel,
        genbank_channel
    )
}