process COLLAPSE {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(sequences), val(meta)
    val strip_gaps

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple
    tuple path("*.json"), val(meta), emit: namefile_tuple

    script:

    """
    pipeline-utils-rs collapse\
    --input-file ${sequences}\
    --output-file ${meta.sample_id}.collapsed.fasta\
    --name-output-file ${meta.sample_id}.namefile.json\
    --sequence-prefix ${meta.sample_id}\
    ${strip_gaps}
    """
}
