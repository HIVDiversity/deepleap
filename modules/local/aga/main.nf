

process AGA{
    input:
    val(sequence_record)
    path(genbank_file)

    output:
    path("*.cds_nt_aln.fasta"), emit: nt_alignment
    path("*.cds_aa_aln.fasta"), emit: aa_alignment
    path("*.json"), emit: metrics

    script:

    """
    echo ">${sequence_record.id}" > ${sequence_record.id}.aga_in.fasta
    echo "${sequence_record.seqString}" >> ${sequence_record.id}.aga_in.fasta
    /home/dlejeune/masters/aga/build/src/aga --global --strict-codon-boundaries --cds-aa-alignments ${sequence_record.id}.cds_aa_aln.fasta --cds-nt-alignments ${sequence_record.id}.cds_nt_aln.fasta --cds-stats-output ${sequence_record.id}.metrics.json ${genbank_file} ${sequence_record.id}.aga_in.fasta ${sequence_record.id}.aga.out.fasta
    """

}