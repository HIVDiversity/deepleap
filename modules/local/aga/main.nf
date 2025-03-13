
process AGA {
    tag "${meta.sample_id}"
    label "aga"

    input:
    tuple path(sample), val(meta)
    path genbank_file

    output:
    tuple path("*_NT_*${meta["region_of_interest"]}.fasta"), val(meta), emit: nt_alignment

    tuple path("*_AA_*${meta["region_of_interest"]}.fasta"), path("*.csv"), val(meta), emit: aa_alignment

    script:

    """
   
    /app/aga \\
    ${task.ext.args ?: ''} \\
    --cds-output . \\
    --protein-output . \\
    --report-output . \\
    --output-prefix ${meta.sample_id} \\
    ${genbank_file} \\
    ${sample} \\
    ${meta.sample_id}.aga.out.unwantedfasta
    """
}
