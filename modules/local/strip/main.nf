process STRIP{
    
    input:
    tuple path(sample), val(meta)
    val(strip_char) // The character(s) to remove from the file

    output:
    tuple  path("*.fasta"), val(meta) , emit: sample_tuple

    script:

    """
    tr -d "${strip_char}" < ${sample} > ${meta.sample_id}.stripped.fasta
    """



}