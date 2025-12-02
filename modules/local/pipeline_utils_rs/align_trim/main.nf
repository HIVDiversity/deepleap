process PAIRWISE_ALIGN_TRIM {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(query_file), path(reference, name: "ref.fasta"), val(meta)
    val log_level

    output:
    tuple path("*.fasta"), val(meta), emit: trimmed_fasta

    script:
    log_flag = log_level == "VERBOSE" ? "--verbose" : ""
    args = task.ext.args ?: ""

    """
    pipeline-utils-rs align-trim \
    --reference-file ${reference} \
    --query-file ${query_file} \
    --output-file ${meta.sample_id}.trimmed.fasta ${log_flag} \
    --stop-aa X \
    ${args}
    """
}
