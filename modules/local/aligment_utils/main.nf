process COLLAPSE{
    tag "$meta.sample_id"
    label "alignment_utils"

    input:
    tuple path(input_file), val(meta)
    

    output:
    tuple  path("*.fasta"), val(meta) , emit: sample_tuple
    tuple path("*.json"), val(meta), emit: namefile_tuple

    script:

    """
    /usr/local/bin/python /app/main.py collapse $input_file ${meta.sample_id}.collapsed.fasta ${meta.sample_id}.names.json
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
    tag "$meta.sample_id"
    label "alignment_utils"

    input:
    tuple path(input_file), val(meta)
    path(ref_file)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    """
    /usr/local/bin/python /app/main.py trim-to-seq --remove-seq $input_file $ref_file ${meta.sample_id}.trimmed.fasta 
    """
}

process DEGAP{
    tag "$meta.sample_id"
    label "alignment_utils"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    """
    /usr/local/bin/python /app/main.py degap $input_file ${meta.sample_id}.degapped.fasta 
    """

}

process EXPAND{
    tag "$meta.sample_id"
    label "alignment_utils"

    input:
    tuple val(meta), path(input_file), path(name_file) // I think 

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    """
    /usr/local/bin/python /app/main.py expand ${input_file} ${name_file} ${meta.sample_id}.expanded.fasta 
    """

}