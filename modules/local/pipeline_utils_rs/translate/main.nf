process TRANSLATE {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(sequences), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:

    """
    pipeline-utils-rs translate\
    --input-file ${sequences}\
    --output-file ${meta.sample_id}.translated.fasta\
    --strip-gaps\
    --drop-incomplete-codons\
    --aa-stop-char X \
    """
}
