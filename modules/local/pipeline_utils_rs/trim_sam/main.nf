process TRIM_SAM {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(input_file), val(meta)
    tuple val(from), val(to)

    output:
    tuple path("*.fasta"), val(meta), emit: trimmed_fasta

    script:
    args = task.ext.args ?: ""

    """
    pipeline-utils-rs trim-sam --input-file ${input_file} --output-file ${meta.sample_id}_trimmed.fasta --trim-from ${from} --trim-to ${to}
    """
}
