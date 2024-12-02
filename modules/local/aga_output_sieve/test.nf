include {AGA_SIEVE} from "./main"

workflow{    
    def metrics_file = file("/home/dlejeune/Documents/aga_test/DLJ_TEST_report.csv")

    meta = [
        sample_id: "CAP001_1000",
        region: "env",
        region_type: "PROT",
        seq_type: "AA"


    ]

    file_ch = channel.of([metrics_file, meta])

    AGA_SIEVE(
        file_ch
    )

}