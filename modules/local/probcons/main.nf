process PROBCONS {
    tag "${meta.sample_id}"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple
    tuple path("*.annotations"), val(meta), emit: annotations

    script:


    """
    probcons -v \\
    -annot ${meta.sample_id}_probcons.annotations \\
    ${task.ext.args ?: ''} \\
    ${input_file} > ${meta.sample_id}_probcons.fasta
    """
}
