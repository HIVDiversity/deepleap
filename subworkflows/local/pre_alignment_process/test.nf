include { PRE_ALIGNMENT_PROCESSING } from "./main"
workflow {
    def input_seqs = file("/home/dlejeune/masters/nf-test-data/test_pre_alignment_processing/CAP409_2000-pool12_inqaba_CDS_NT_envelope-polyprotein.fasta")
    def meta = ["sample_id": "CAP409_2000-pool12_inqaba"]
    def ref = file("/home/dlejeune/Documents/real_data/hxb2-env.fasta")

    def input_ch = channel.from([[input_seqs, meta]])
    PRE_ALIGNMENT_PROCESSING(
        input_ch,
        true,
        ref,
    )

    PRE_ALIGNMENT_PROCESSING.out.translated_collapsed_tuples.view()
}
