process DRAW_TREE_HEATMAP {
    tag "${meta.sample_id}"

    input:
    tuple path(tree), path(alignment), path(baseline), val(meta)

    output:
    tuple path("*.png"), val(meta), emit: heatmap_tuple

    script:
    """
    touch ${meta.sample_id}.heatmap.png
    """
}
