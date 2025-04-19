include {FUNCTIONAL_FILTER} from "./main"

workflow {
    def input_file = file("/home/dlejeune/masters/nf-test-data/test_functional_filter/CAP037_2000-pool5_uw_CDS_NT_envelope-polyprotein.fasta")
    def meta = ["sample_id": "CAP037_2000-pool5_uw"]

    def in_channel = channel.from([[input_file, meta]])

    FUNCTIONAL_FILTER(
        in_channel
    )
}