process FILTER_AGA_OUTPUT{
    tag "${meta.sample_id}"
    label "process_aga_output"

    input:
    tuple  path(aga_aa_cds_output), path(aga_metrics), val(meta)

    output:
    tuple path("*.filtered.fasta"), val(meta), emit: filtered_tuples
    path("*.rejected.fasta"), emit: rejected_records

    script:

    """
    /usr/local/bin/parse-aga-output \\
    --metric-file ${aga_metrics} \\
    --fasta-file ${aga_aa_cds_output} \\
    --ok-output ${meta.sample_id}.aa.filtered.fasta \\
    --rejected-output ${meta.sample_id}.aa.rejected.fasta
    """
}