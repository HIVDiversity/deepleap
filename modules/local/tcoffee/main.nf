process TCOFFEE {
    input:
    tuple file(sample), val(meta)

    output:
    tuple path("*.fasta_aln"), val(meta), emit: sample_tuple
    tuple path("*.score_html"), val(meta), emit: score_tuples

    script:

    args = task.ext.args ?: ""

    """
    t_coffee ${args} -thread 0 -seq ${sample} -output fasta_aln,score_html 
    """
}
