process PRANK {
    tag "${meta.sample_id}"
    label "prank"

    input:
    tuple file(sample), val(meta)

    output:
    tuple path("*.fas"), val(meta), emit: sample_tuple

    script:

    args = task.ext.args ?: ""

    """
    prank ${args} -d=${sample} -o=${meta.sample_id}_prank -f=fasta
    """
}
