process FIX_NAMES{
    tag "${meta.sample_id}"
    label "fix_naming"

    input:
    tuple path(sample), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple
    path("*.log"), emit: log

    script:
    // TODO: Again, paramaterize the sequence prefix here. 

    """
    /usr/local/bin/fix-seq-naming \\
    -i ${sample} \\
    -o ${meta.sample_id}.renamed.fasta \\
    -n ${meta.sample_id}.names.json \\
    -s ENV_NT
    """
}