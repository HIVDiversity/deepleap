process PAIRWISE_ALIGN_TRIM {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(aligned_sequences), val(meta)
    path reference
    val log_level

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:
    log_flag = log_level == "VERBOSE" ? "--verbose" : ""

    """
    pipeline-utils-rs align-consensus \
    --reference-file ${reference} \
    --query-file ${aligned_sequences} \
    --output-file ${meta.sample_id}.consensus.trimmed.fasta ${log_flag} \
    ${task.ext.args}
    """
}
