include {FILTER_AGA_OUTPUT} from "./main"

workflow{
    def aligned_aa_seqs = file("/home/dlejeune/masters/nf-test-data/test_filter_aga/7_envelope_polyprotein.aa.fasta")
    def metrics_file = file("/home/dlejeune/masters/nf-test-data/test_filter_aga/metrics.csv")

    meta = [
        sample_id: "CAP001_1000"
    ]

    file_ch = channel.of([aligned_aa_seqs, metrics_file, meta])

    FILTER_AGA_OUTPUT(
        file_ch
    )

}