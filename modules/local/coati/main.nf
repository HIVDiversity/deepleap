

process COATI{
    tag "TODO"
    container "dlejeune/coati:latest"

    input:
    path(input_file)

    output:
    path("*.coati.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    coati alignpair $input_file --output ${prefix}.coati.fasta
    """


}