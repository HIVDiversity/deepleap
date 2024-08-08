

process ADJUST{
    tag "TODO"

    input:
    path(input_file)

    output:
    path("*.corrected.fasta"), emit: fasta

    script:

    newFileName = input_file.baseName + ".corrected.fasta"

    """
    python /home/dlejeune/masters/codon_align/codon_adjust.py ${input_file} ${newFileName}
    """
}