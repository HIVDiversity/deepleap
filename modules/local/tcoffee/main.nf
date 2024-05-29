process TCOFFEE{
    tag "TODO"
    container "pegi3s/tcoffee:12.00.7"

    input:
    path(input_file)

    output:
    path("*.fasta_aln"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    t_coffee -seq=$input_file -output=fasta -run_name=${prefix}.tcoffee
    """


}