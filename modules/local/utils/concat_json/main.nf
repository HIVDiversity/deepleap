process CONCAT_JSON_FILES {
    input:
    tuple val(json_files), val(grouping_id)

    output:
    tuple path("*.json"), val(grouping_id), emit: json_tuple

    script:
    """
    jq -s 'reduce .[] as \$item ({}; . * \$item)' ${json_files.join(' ')} > CAP${grouping_id}.json
    """
}
