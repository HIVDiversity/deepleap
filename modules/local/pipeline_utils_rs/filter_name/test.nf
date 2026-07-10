include { FILTER_NAME } from "./main"

workflow {

    nt_file = file("${launchDir}/test_data/inputs/sample_a.fasta")

    meta = ["sample_id": "SAMPLE_A"]

    input_ch = channel.from([[nt_file, meta]])
    regex_ch = channel.value("145")


    FILTER_NAME(
        input_ch,
        regex_ch,
    )

    FILTER_NAME.out.filtered_tuples.view()
    FILTER_NAME.out.rejected_records.view()
}
