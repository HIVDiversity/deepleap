process FILTER_BY_KMER {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(input_file), val(meta)
    val start_kmer
    val end_kmer

    output:
    tuple path("*.fasta"), val(meta), emit: trimmed_fasta

    script:

    """
    pipeline-utils-rs filter-by-kmer --input-file ${input_file} --output-file ${meta.sample_id}_kmer_filtered.fasta --start-kmers ${start_kmer} --end-kmers ${end_kmer}
    """
}
