process MACSE {
    tag "${meta.sample_id}"
    label "codonAligner"

    input:
    tuple file(sample), val(meta)

    output:
    tuple path("*_macseAA.fasta"), val(meta), emit: sample_tuple

    script:

    args = task.ext.args ?: ""

    """
    macse -prog alignSequences ${args} -seq ${sample} -out_AA ${meta.sample_id}_macseAA.fasta
    """
}
