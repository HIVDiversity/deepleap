process CONCAT_FASTA_FILES {
    input:
    tuple val(fasta_files), val(grouping_id)

    output:
    tuple path("*.fasta"), val(grouping_id), emit: fasta_tuple

    script:
    """
    cat ${fasta_files.join(' ')} > CAP${grouping_id}_merged.fasta
    """
}
