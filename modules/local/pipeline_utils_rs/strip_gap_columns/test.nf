include { STRIP_GAP_COLS } from "./main"

workflow {

    nt_file = file("${launchDir}/test_data/inputs/small_inputs/small_gappy_msa.fasta")

    meta = ["sample_id": "SAMPLE_A"]

    input_ch = channel.from([[nt_file, meta]])


    STRIP_GAP_COLS(
        input_ch
    )

    STRIP_GAP_COLS.out.view()
}
