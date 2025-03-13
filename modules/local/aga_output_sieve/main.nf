process AGA_SIEVE {
    tag "${meta.sample_id}"

    input:
    tuple path(aga_metrics), val(meta)

    output:
    tuple path("*.txt"), val(meta), emit: names_to_keep
    tuple path("*.csv"), val(meta), emit: annotated_report

    script:

    """
    /app/.venv/bin/python /app/src/main.py \\
    ${task.ext.args ?: ''} \\
    ${aga_metrics} \\
    ${meta.sample_id}_annotated_report.csv \\
    ${meta.sample_id}_names_to_keep.txt \\
    ${meta.region_of_interest}
    """
}
