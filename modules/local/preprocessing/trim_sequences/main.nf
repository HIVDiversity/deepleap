process TRIM_SEQUENCES{
    tag "$meta.sample_id"
    label "pipeline_utils_rs"

    input:
    tuple path(sequences), path(trimmed_consensus), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    """
    pipeline-utils-rs align-and-trim\
    --query-sequences ${sequences}\
    --output-file ${meta.sample_id}.trimmed.fasta\
    --consensus-sequence ${trimmed_consensus}\
    --output-type AA\
    ${task.ext.args}

    """


}