process SEQTK_SUBSEQ{
    tag "${meta.sample_id}"

    input:
    tuple path(fasta), path(names), val(meta)

    output:
    tuple path("*.filtered.fasta"), val(meta), emit: filtered_tuples
    // path("*.rejected.fasta"), emit: rejected_records

    script:

    """
    /usr/local/bin/seqtk-1.4/seqtk  subseq ${fasta} ${names} > ${meta.sample_id}.filtered.fasta
    """
}