include { TRIM_TO_STOP } from "./main"

workflow {

    nt_file = file("${launchDir}/test_data/inputs/sample_a.fasta")

    meta = ["sample_id": "SAMPLE_A"]

    input_ch = channel.from([[nt_file, meta]])


    TRIM_TO_STOP(
        input_ch
    )

    TRIM_TO_STOP.out.view()
}
