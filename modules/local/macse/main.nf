process MACSE {
    tag "${meta.sample_id}"
    label "codonAligner"

    input:
    tuple file(sample), val(meta)

    output:
    tuple path("*.fas"), val(meta), emit: sample_tuple

    script:

    args = task.ext.args ?: ""

    """
    pagan ${args} -s ${sample} -o ${meta.sample_id}_pagan.fasta -f=fasta
    """
}
