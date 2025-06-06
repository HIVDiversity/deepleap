process EXTRACT_SEQ_FROM_GB {
    tag "${genbank_file.baseName}"
    label "pipeline_utils_rs"

    input:
    path genbank_file
    val feature_of_interest

    output:
    path ("*.fasta"), emit: extracted_sequence_fasta

    script:
    """
    pipeline-utils-rs gb-extract\
    --input-file ${genbank_file}\
    --output-file ${feature_of_interest}.fasta\
    --seq-name ${feature_of_interest}
    """
}
