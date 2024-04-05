

process COATI{
    tag "TODO"
    container "dlejeune/coati:latest"

    input:
    path(input_file)
    val(meta)

    output:
    path("*.coati.fasta"), emit: fasta

    script:

    """
    coati alignpair $input_file --output ${meta.read_id}.coati.fasta
    """


}