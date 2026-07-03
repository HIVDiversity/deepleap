include { FILTER_LENGTH } from "./main"

workflow {

    nt_file = file("${launchDir}/test_data/inputs/sample_a.fasta")

    meta = ["sample_id": "SAMPLE_A"]

    input_ch = channel.from([[nt_file, meta]])


    FILTER_LENGTH(
        input_ch
    )

    FILTER_LENGTH.out.filtered_tuples.view()
    FILTER_LENGTH.out.rejected_records.view()
    FILTER_LENGTH.out.report.view()
}
