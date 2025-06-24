process TCOFFEE {
    input:
    tuple file(sample), val(meta)

    output:
    tuple path("*.fasta"), val(meta)

    script:

    args = task.ext.args ?: ""

    """
    t_coffee ${args} --thread 0 -seq ${sample} -output fasta_aln
    """
}
