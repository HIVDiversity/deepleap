

process MACSE{
    tag "TODO"
    container "dlejeune/macse:2.07"    

    input:
    path(input_file)
    

    output:
    path("*.nt.fasta"), emit: nt_fasta
    path("*.aa.fasta"), emit: aa_fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    java -jar -Xmx2G /usr/local/bin/macse/macse.jar \\
    -prog alignSequences \\
    -seq $input_file \\
    -out_NT ${params.run_name}.nt.fasta \\
    -out_AA ${params.run_name}.aa.fasta

    """


}