include { LENGTH_BASED_FILTERING } from "./main.nf"

workflow {

    nt_file = file("${launchDir}/test_data/inputs/sample_a.fasta")

    meta = ["sample_id": "SAMPLE_A"]

    input_ch = channel.from([[nt_file, meta]])

    LENGTH_BASED_FILTERING(
        input_ch
    )

    LENGTH_BASED_FILTERING.out.trimmed_to_stop_nt.view()
    LENGTH_BASED_FILTERING.out.filtered_tuples.view()
    LENGTH_BASED_FILTERING.out.rejected_records.view()
    LENGTH_BASED_FILTERING.out.report.view()
}
