process VIRULIGN {
    tag "${meta.sample_id}"
    label "codonAligner"

    input:
    tuple file(sample), val(meta)
    file reference

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    args = task.ext.args ?: ""

    """
    virulign ${reference} ${sample} ${args} --exportKind GlobalAlignment --exportAlphabet AminoAcids > ${meta.sample_id}_virulign.fasta
    """
}
