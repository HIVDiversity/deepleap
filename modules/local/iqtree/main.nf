process IQTREE {
    input:
    tuple file(alignment), val(meta)

    output:
    tuple file("*.treefile"), val(meta), emit: tree_tuple
    path ("*.tree*"), emit: iqtree_output

    script:

    def args = task.ext.args ?: ""

    """
    iqtree3 -s ${alignment} --prefix ${meta.sample_id}.tree -T AUTO -v ${args}
    """
}
