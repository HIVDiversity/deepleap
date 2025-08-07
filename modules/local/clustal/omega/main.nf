process CLUSTAL_OMEGA {
    tag "${meta.sample_id}"
    label "clustal"

    input:
    tuple file(sample), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    args = task.ext.args ?: ""

    """
    clustalo ${args} --in ${sample} --out ${meta.sample_id}_clustalo.fasta --outfmt fasta --threads=${task.cpus}
    """
}
