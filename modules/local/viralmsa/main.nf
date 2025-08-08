process VIRALMSA {
    tag "${meta.sample_id}"

    input:
    tuple file(sample), val(meta)
    file reference

    output:
    tuple path("viralmsa_output/*.aln"), val(meta), emit: sample_tuple

    script:

    args = task.ext.args ?: ""

    """
    ViralMSA.py --reference ${reference} --sequences ${sample} -e None --viralmsa_dir ./tmp --output ./viralmsa_output/ ${args}
    """
}
