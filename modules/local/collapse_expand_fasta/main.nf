process COLLAPSE {
    tag "$meta.sample_id"
    label "collapse_expand"

    input:
    tuple path(input_file), val(meta)
    

    output:
    tuple  path("*.fasta"), val(meta) , emit: sample_tuple
    tuple path("*.json"), val(meta), emit: namefile_tuple

    script:

    """
    /usr/local/bin/collapse-expand-fasta $input_file ${meta.sample_id}.collapsed.fasta ${meta.sample_id}.names.json ${meta.sample_id}_CLPSD
    """

}