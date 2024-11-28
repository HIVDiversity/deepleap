

process AGA{
    tag "${meta.sample_id}"
    label "aga"

    
    input:
    tuple path(sample), val(meta)
    path(genbank_file)

    output:
    tuple path("*_NT_*.fasta"), val(meta), emit: nt_alignment
    
    tuple path("*_AA_*.fasta"), path("*.aga_metrics.csv"),val(meta), emit: aa_alignment

    script:

    """
   
    /app/aga \\
    --local \\
    --cds-output . \\
    --protein-output . \\
    --report-output . \\

    --cds-aa-alignments  ${meta.sample_id}.aa.fasta \\
    --cds-nt-alignments ${meta.sample_id}.nt.fasta \\
    --cds-name ${meta.cds_name} \\
    --cds-stats-output ${meta.sample_id}.aga_metrics.csv \\
    ${genbank_file} \\
    ${sample} \\
    ${meta.sample_id}.aga.out.fasta
    """

}