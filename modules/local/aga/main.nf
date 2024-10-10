

process AGA{
    tag "${meta.sample_id}"
    label "aga"

    
    input:
    tuple path(sample), val(meta)
    path(genbank_file)

    output:
    tuple path("*${meta.cds_name}.nt.fasta"), val(meta), emit: nt_alignment
    
    tuple path("*${meta.cds_name}.aa.fasta"), path("*.aga_metrics.csv"),val(meta), emit: aa_alignment

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