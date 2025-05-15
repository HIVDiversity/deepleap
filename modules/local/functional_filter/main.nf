process FUNCTIONAL_FILTER {
    tag "${meta.sample_id}"

    input:
    tuple path(sequences), val(meta)

    output:
    tuple path("*.functional.fasta"), val(meta), emit: filtered_tuples
    path ("*.rejected.fasta"), emit: rejected_records
    path ("*.csv"), emit: report

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
