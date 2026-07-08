process FILTER_LENGTH {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*_length_filtered.fasta"), val(meta), emit: filtered_tuples
    tuple path("*_length_rejected.fasta"), val(meta), emit: rejected_records
    tuple path("*.csv"), val(meta), emit: report

    script:

    """
    pipeline-utils-rs filter-by-length \
    --input-file ${input_file} \
    --output-file ${meta.sample_id}_length_filtered.fasta \
    --report-file ${meta.sample_id}_length_filter_report.csv \
    --rejected-seq-output ${meta.sample_id}_length_rejected.fasta \
    ${task.ext.args}
    """
}
