process FIX_NAMES{
    tag "${meta.sample_id}"
    label "fix_naming"

    input:
    tuple path(sample), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple
    path("*.log"), emit: log

    script:

    """
    
    """
}