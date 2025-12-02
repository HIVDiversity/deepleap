process MINIMAP_TWO {
    tag "${meta.sample_id}"
    label "aga"

    input:
    tuple path(sample), val(meta)
    path ref_file

    output:
    tuple path("*.fasta"), val(meta), emit: mapped_tuple

    script:

    """
    minimap2 -a ${ref_file} ${sample} > ${meta.sample_id}_mapped.fasta
    """
}
