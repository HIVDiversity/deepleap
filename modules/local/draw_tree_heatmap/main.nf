process DRAW_TREE_HEATMAP {
    tag "${meta.sample_id}"
    label "py_uv"

    input:
    tuple path(tree), path(msa), val(meta)

    output:
    tuple path("*.png"), val(meta), emit: tree_heatmap_tuple

    script:

    """
    tree_highlighter_plot.py ${tree} ${msa} ${meta.baseline_id} ${meta.sample_id}_tree_highlighter.png --plot-title ${meta.sample_id}
    """
}
