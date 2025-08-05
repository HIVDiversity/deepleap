process TCOFFEE {
    tag "${meta.sample_id}"
    label "tcoffee"

    input:
    tuple file(sample), val(meta)

    output:
    tuple path("*.fasta_aln"), val(meta), emit: sample_tuple
    tuple path("*.score_html"), val(meta), emit: score_tuples

    script:

    args = task.ext.args ?: ""

    """
    echo \$HOME
    t_coffee ${args} -debug -thread 0 -seq ${sample} -output fasta_aln,score_html 
    """
}

process REGRESSIVE_TCOFFEE {
    tag "${meta.sample_id}"
    label "tcoffee"

    input:
    tuple file(sample), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple
    tuple path("*_tree.mbed"), val(meta), emit: tree_tuple

    script:

    args = task.ext.args ?: ""

    """
    echo \$HOME
    t_coffee -reg ${args} -debug -thread 0 -seq ${sample} -outfile ${meta.sample_id}_tcoffeealn.fasta -outtree ${meta.sample_id}_tree.mbed
    """
}
