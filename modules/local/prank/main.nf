

process PRANK{
    tag "TODO"
    container "dlejeune/prank:latest"
    

    input:
    path(input_file)

    output:
    path("*.best.fas"), emit: fasta
    path("*.log"), emit: log

    script:

    """
    /usr/local/bin/prank/prank -d=$input_file -o=prank_output.best.fas -F > prank.log


    """


}