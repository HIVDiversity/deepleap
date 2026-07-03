process STRIP_GAP_COLS {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: stripped_fasta

    script:

    """
    pipeline-utils-rs strip-gap-cols --input-file ${input_file} --output-file ${meta.sample_id}_trimmed_to_stop_codon.fasta 
    """
}
