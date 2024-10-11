

process AGA{
    tag "${meta.sample_id}"
    label "aga"

    
    input:
    tuple path(sample), val(meta)
    path(genbank_file)

    output:
    tuple path("*.nt.fasta"), val(meta), emit: nt_alignment
    
    tuple path("*.aa.fasta"), path("*.aga_metrics.csv"),val(meta), emit: aa_alignment

    script:

    """
   
    /app/aga \\
    --global \\
    --strict-codon-boundaries \\
    --cds-aa-alignments  ${meta.sample_id}.aa.fasta \\
    --cds-nt-alignments ${meta.sample_id}.nt.fasta \\
    --cds-name ${meta.cds_name} \\
    --cds-stats-output ${meta.sample_id}.aga_metrics.csv \\
    ${genbank_file} \\
    ${sample} \\
    ${meta.sample_id}.aga.out.fasta
    """

}