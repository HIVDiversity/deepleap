process REMOVE_SEQUENCE {
    input:
    tuple file(fasta_file), val(meta)
    val seq_to_remove_name

    output:
    tuple path("*.fasta"), val(meta), emit: fasta_tuple

    script:
    """
    awk '/^>/{keep = (\$1 != ">${seq_to_remove_name}")} keep' > ${meta.sample_id}.fasta
    """
}
