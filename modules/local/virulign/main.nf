

process VIRULIGN{
    tag "TODO"
    container "dlejeune/virulign:v1.0.1"
    

    input:
    path(input_file)
    path(reference)

    output:
    path("*.fasta"), emit: fasta
    path("*.log"), emit: log

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    virulign $reference $input_file --exportKind GlobalAlignment --exportAlphabet Nucleotides > alignment.fasta  2> virulign.log      


    """


}