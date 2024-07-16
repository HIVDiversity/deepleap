process MAFFT{
    tag "TODO"
    container "dlejeune/mafft:7.525"

    input:
    path(input_file)

    output:
    path("*.mafft.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    mafft $input_file > ${prefix}.mafft.fasta
    """


}

process MAFFT_ADD{
    tag "TODO"
    container "dlejeune/mafft:7.525"

    input:
    path(input_file)
    path(ref_file)

    output:
    path("*.mafft.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    mafft --add $ref_file  $input_file > ${prefix}.ref.mafft.fasta
    """
}