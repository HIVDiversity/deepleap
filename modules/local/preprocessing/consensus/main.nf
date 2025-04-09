process GET_CONSENSUS{
    tag "$meta.sample_id"
    label "pipeline_utils_rs"

    input:
    tuple path(aligned_sequences), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    """
    pipeline-utils-rs get-consensus \
    --input-msa ${aligned_sequences} \
    --output-file ${meta.sample_id}.consensus.fasta \
    --consensus-name ${meta.sample_id}_consensus
    """


}