process MINDIST {
    tag "${meta.sample_id}"

    input:
    tuple path(aligned_sequences), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:
    """
    touch ${meta.sample_id}.mindist.fasta
    """
}
