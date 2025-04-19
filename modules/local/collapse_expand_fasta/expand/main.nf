process EXPAND {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(collapsed_sequences), path(namefile), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    """
    pipeline-utils-rs expand\
    --input-file ${collapsed_sequences}\
    --name-input-file ${namefile}\
    --output-file ${meta.sample_id}.uncollapsed.fasta\
    """
}
