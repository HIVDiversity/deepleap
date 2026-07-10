process MINDIST {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(aligned_sequences), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:
    """
    pipeline-utils-rs -i ${aligned_sequences} -o ${meta.sample_id}_mindist.fasta -a first -m exact
    """
}
