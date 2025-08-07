process CLUSTALW {
    tag "${meta.sample_id}"
    label "clustal"

    input:
    tuple file(sample), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    args = task.ext.args ?: ""

    """
    clustalw2 -ALIGN ${args} -INFILE=${sample} -OUTPUT=FASTA -OUTFILE=${meta.sample_id}_clustalw.fasta -TYPE=PROTEIN
    """
}
