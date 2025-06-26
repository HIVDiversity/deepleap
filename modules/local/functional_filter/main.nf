process FUNCTIONAL_FILTER {
    tag "${meta.sample_id}"

    input:
    tuple path(sequences), val(meta)

    output:
    tuple path("*.functional.fasta"), val(meta), emit: filtered_tuples
    tuple path("*.rejected.fasta"), val(meta), emit: rejected_records
    tuple path("*.csv"), val(meta), emit: report

    script:
    """
    functional-filter ${sequences} ${meta.sample_id}.functional.fasta \
    --output-type FASTA\
    --output-rejected ${meta.sample_id}.rejected.fasta\
    --report-path ${meta.sample_id}.functional_report.csv\
    --strip-gaps\
    ${task.ext.args}
    """
}
