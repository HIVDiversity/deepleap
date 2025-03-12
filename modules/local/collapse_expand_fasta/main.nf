process COLLAPSE {
    tag "$meta.sample_id"
    label "collapse_expand"

    input:
    tuple path(input_file), val(meta)
    val(prefix) // This is actually the bit to put after the sample ID
    val(strip_gaps)
    

    output:
    tuple  path("*.fasta"), val(meta) , emit: sample_tuple
    tuple path("*.json"), val(meta), emit: namefile_tuple
    
    script:
    def gap_flag = ""
    if (strip_gaps){
        gap_flag = "-s"
    }
    //TODO: this code should be updated to automatically set the sequence type...

    """
    /usr/local/bin/collapse-expand-fasta \\
    -i $input_file \\
    -o ${meta.sample_id}_${prefix}.collapsed.fasta \\
    -n ${meta.sample_id}.names.json \\
    -p ${meta.sample_id}_${prefix} \\
    ${gap_flag} 
    """

}