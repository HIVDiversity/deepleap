process FILTER_BY_KMER {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(input_file), val(meta)
    val start_kmer
    val end_kmer

    output:
    tuple path("*.kmer_filtered.fasta"), val(meta), emit: filtered_tuples
    tuple path("*.kmer_rejected.fasta"), val(meta), emit: rejected_records
    tuple path("*.csv"), val(meta), emit: report

    script:

    """
    pipeline-utils-rs filter-by-kmer \
    --input-file ${input_file} \
    --output-file ${meta.sample_id}_kmer_filtered.fasta \
    --report-file ${meta.sample_id}_kmer_filter_report.csv \
    --rejected-seq-output ${meta.sample_id}.kmer_rejected.fasta \
    --start-kmers ${start_kmer} \
    --end-kmers ${end_kmer}
    """
}
