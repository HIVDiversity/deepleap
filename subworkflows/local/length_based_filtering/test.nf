include { LENGTH_BASED_FILTERING } from "./main.nf"

workflow {

    nt_file = file("${launchDir}/test_data/inputs/sample_a.fasta")

    meta = ["sample_id": "SAMPLE_A"]

    input_ch = channel.from([[nt_file, meta]])
    kmer_filtering_params = ["use_kmer_filtering": true, "start_kmers": "ATG", "end_kmers": "TTA"]

    LENGTH_BASED_FILTERING(
        input_ch,
        kmer_filtering_params,
    )

    LENGTH_BASED_FILTERING.out.trimmed_to_stop_nt.view()
    LENGTH_BASED_FILTERING.out.length_filtered_tuples.view()
    LENGTH_BASED_FILTERING.out.length_rejected_records.view()
    LENGTH_BASED_FILTERING.out.length_filter_report.view()
}
