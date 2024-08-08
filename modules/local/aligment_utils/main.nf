process COLLAPSE{
    tag "TODO"
    label "alignment_utils"

    input:
    path(input_file)
    

    output:
    path("*.fasta"), emit: samples
    path("*.json"), emit: namefile

    script:
    prefix = input_file.baseName.tokenize('.')[0]

    """
    /usr/local/bin/python /app/main.py collapse $input_file ${prefix}.collapsed.fasta ${prefix}.names.json
    """
}

process REVERSE{
    tag "TODO"
    label "alignment_utils"

    input:
    path(input_file)
    val(prefix)

    output:

    path("*.fasta"), emit: fasta
    path("*.json"), emit: namefile

    script:
    prefix = input_file.baseName.tokenize('.')[0]

    """
    /usr/local/bin/python /app/main.py collapse $input_file ${prefix}.collapsed.fasta ${prefix}.names.json
    """
}

process ADD_REF{
    tag "TODO"
    label "alignment_utils"

    input:
    path(input_file)
    path(ref_file)

    output:
    path("*.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]
    """
    /usr/local/bin/python /app/main.py add-ref $input_file ${prefix}.collapsed.fasta ${prefix}.names.json
    """

}

process TRIM_TO_SEQ{
    tag "TODO"
    label "alignment_utils"

    input:
    path(input_file)
    path(ref_file)

    output:
    path("*.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    /usr/local/bin/python /app/main.py trim-to-seq --remove-seq $input_file $ref_file ${prefix}.trimmed.fasta 
    """
}

process DEGAP{
    tag "TODO"
    label "alignment_utils"

    input:
    path(input_file)
    path(ref_file)

    output:
    path("*.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    /usr/local/bin/python /app/main.py degap $input_file ${prefix}.degapped.fasta 
    """

}

process EXPAND{
    tag "TODO"
    label "alignment_utils"

    input:
    path(input_file)
    path(name_file)

    output:
    path("*.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    /usr/local/bin/python /app/main.py expand $input_file ${prefix}.expanded.fasta ${name_file}
    """

}