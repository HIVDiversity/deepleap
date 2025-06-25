process KMER_TRIM_SEQUENCES {
    tag "${meta.sample_id}"
    label "pipeline_utils_rs"

    input:
    tuple path(sequences), path(reference, name: "reference.fasta"), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: sample_tuple

    script:
    args = task.ext.args ?: ""

    """
    pipeline-utils-rs kmer-trim\
    --query-seq-file ${sequences}\
    --output-file ${meta.sample_id}.trimmed.fasta\
    --ref-seq-file ${reference}\
    --output-type NT\
    --aa-stop-char X \
    ${args}

    """
}
