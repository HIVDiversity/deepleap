process IQTREE {
    input:
    tuple file(alignment), val(meta)

    output:
    tuple file("*.tree*"), val(meta), emit: tree_tuple

    script:

    def args = task.ext.args ?: ""

    """
    iqtree2 -s ${alignment} --prefix ${meta.sample_id}.tree -T AUTO -v ${args}
    """
}
