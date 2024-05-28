process CLUSTALO{
    tag "TODO"
    container "dlejeune/clustalo:1.2.4"

    input:
    path(input_file)

    output:
    path("*.clustalo.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
   clustalo --in $input_file --out ${prefix}.clustalo.fasta
    """


}