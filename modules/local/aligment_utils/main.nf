process COLLAPSE{
    tag "TODO"
    label "alignment_utils"

    input:
    path(input_file)
    val(prefix)

    output:
    path("*.fasta"), emit: fasta
    path("*.json"), emit: namefile

    script:


    """
    /usr/local/bin/python /app/main.py collapse $input_file ${prefix}.collapsed.fasta ${prefix}.names.json
    """
}