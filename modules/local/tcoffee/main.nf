process TCOFFEE {
    input:
    tuple file(sample), val(meta)

    output:
    tuple path("*.fasta"), val(meta)

    script:
    """
    t_coffee 
    """
}
