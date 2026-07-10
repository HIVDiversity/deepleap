process FILTER_NAME {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(input_file), val(meta)
    val regex

    output:
    tuple path("*_name_filtered.fasta"), val(meta), emit: filtered_tuples
    tuple path("*_name_rejected.fasta"), val(meta), emit: rejected_records

    script:

    """
    pipeline-utils-rs filter-by-name \
    --input-file ${input_file} \
    --output-file ${meta.sample_id}_name_filtered.fasta \
    --rejected-seq-output ${meta.sample_id}_name_rejected.fasta \
    --pattern ${regex} \
    --exclude \
    """
}
