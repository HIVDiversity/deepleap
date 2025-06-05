process ADD_SEQUENCES {
    input:
    tuple val(fasta_files), val(meta)

    output:
    tuple path("*.fasta"), val(meta), emit: fasta_tuple

    script:
    """
    cat ${fasta_files.join(' ')} > ${meta.sample_id}.fasta
    """
}
