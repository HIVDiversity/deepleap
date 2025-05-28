process TRIM_CONSENSUS {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(aligned_sequences), val(meta)
    path reference

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    """
    pipeline-utils-rs align-consensus \
    --reference-file ${reference} \
    --query-file ${aligned_sequences} \
    --output-file ${meta.sample_id}.consensus.trimmed.fasta \
    --output-seq-name ${meta.sample_id}_consensus_trimmed \
    --strip-gaps \
    --output-type NT \
    ${task.ext.args}
    """
}
