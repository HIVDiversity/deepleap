process DRAW_TREE_HEATMAP {
    tag "${meta.sample_id}"
    label "py_uv"

    input:
    tuple path(tree), path(msa), path(baseline), val(meta)

    output:
    tuple path("*.png"), val(meta), emit: tree_heatmap_tuple

    script:



    """
    SEQ_NAME=\$(grep "^>" "${baseline}" | head -n 1 | sed 's/^>//')
    tree_highplot ${tree} ${msa} ${meta.sample_id}_tree_highlighter.png \$SEQ_NAME --plot-title ${meta.sample_id}
    """
}
