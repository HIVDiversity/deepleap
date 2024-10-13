process COLLAPSE {
    tag "$meta.sample_id"
    label "collapse_expand"

    input:
    tuple path(input_file), val(meta)
    

    output:
    tuple  path("*.fasta"), val(meta) , emit: sample_tuple
    tuple path("*.json"), val(meta), emit: namefile_tuple
    
    script:
    //TODO: the hardcoded ENV and AA values in the -p flag should be parameterised

    """
    /usr/local/bin/collapse-expand-fasta \\
    -i $input_file \\
    -o ${meta.sample_id}.collapsed.fasta \\
    -n ${meta.sample_id}.names.json \\
    -p ${meta.sample_id}_ENV_AA \\
    -s 
    """

}