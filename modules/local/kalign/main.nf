process KALIGN{
    tag "TODO"
    container "dlejeune/kalign:3.4.0"

    input:
    path(input_file)

    output:
    path("*.kalign.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    kalign -i $input_file -o ${prefix}.kalign.fasta --type dna 
    """


}