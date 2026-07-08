include { FILTER_BY_KMER } from "./main"

workflow {

    nt_file = file("${launchDir}/test_data/inputs/small_inputs/kmer_filter_test.fasta")

    meta = ["sample_id": "SAMPLE_A"]
    start_kmers = channel.value("ATG")
    end_kmers = channel.value("TGA,TAG,TAA")

    input_ch = channel.from([[nt_file, meta]])



    FILTER_BY_KMER(
        input_ch,
        start_kmers,
        end_kmers,
    )

    FILTER_BY_KMER.out.view()
}
