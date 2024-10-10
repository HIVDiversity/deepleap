

process AGA{
    tag "${meta.sample_id}"
    label "aga"

    
    input:
    tuple path(sample), val(meta)
    path(genbank_file)

    output:
    path("*${meta.cds_name}.nt.fasta"), emit: nt_alignment
    path("*${meta.cds_name}.aa.fasta"), emit: aa_alignment
    path("*.aga_metrics.csv"), emit: metrics

    script:

    """
   
    /app/aga \\
    --global \\
    --strict-codon-boundaries \\
    --cds-aa-alignments ./ \\
    --cds-nt-alignments ./ \\
    --cds-stats-output ${meta.sample_id}.aga_metrics.csv \\
    ${genbank_file} \\
    ${sample} \\
    ${meta.sample_id}.aga.out.fasta
    """

}