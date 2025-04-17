process REVERSE_TRANSLATE {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(aa_file), path(nt_file), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    """
    pipeline-utils-rs reverse-translate\
    --aa-filepath ${aa_file}\
    --nt-filepath ${nt_file}\
    --output-file-path ${meta.sample_id}.reverse_translated.fasta
    """
}
