

process AGA{
    tag "${meta.sample_id}"
    label "aga"

    
    input:
    tuple path(sample), val(meta)
    path(genbank_file)

    output:
    tuple path("*_NT_*.fasta"), val(meta), emit: nt_alignment
    
    tuple path("*_AA_*.fasta"), path("*.csv"), val(meta), emit: aa_alignment

    script:

    """
   
    /app/aga \\
    --local \\
    --cds-output . \\
    --protein-output . \\
    --report-output . \\
    --output-prefix ${meta.sample_id} \\
    ${genbank_file} \\
    ${sample} \\
    ${meta.sample_id}.aga.out.unwantedfasta
    """

}