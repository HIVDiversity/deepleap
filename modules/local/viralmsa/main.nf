process VIRALMSA{
    tag "TODO"
    container "niemasd/viralmsa:1.1.44"

    input:
    path(input_file)
    path(ref_file)

    output:
    path("*"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    python3 /usr/local/bin/ViralMSA.py -s $input_file -r $ref_file -o output -e nn
    """


}