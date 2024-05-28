process MUSCLE{
    tag "TODO"
    container "dlejeune/muscle:5.1.0"

    input:
    path(input_file)

    output:
    path("*.muscle.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    muscle -nt -align $input_file -output ${prefix}.muscle.fasta
    """


}