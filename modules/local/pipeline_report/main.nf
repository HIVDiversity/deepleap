process PIPELINE_REPORT {
    scratch true

    input:
    path pre_files, stageAs: "pre_files/*"
    path post_files, stageAs: "post_files/*"
    path functional_filter_files, stageAs: "func_filter_files/*"

    output:
    path "output_dir/*"

    script:

    json = groovy.json.JsonOutput.toJson(params).replace("\"", "\\\"")

    """
    git config --global --add safe.directory "*"
    commitid="\$(cd ${workflow.projectDir}; git log --pretty=tformat:"%H" -n1 )"
    tag="\$(cd ${workflow.projectDir}; git describe --tags --abbrev=0  )"
    echo "${json}" > temp_params.json
    
    generate-pipeline-report pre_files/ \\
     post_files/ \\
     func_filter_files/ \\
     ./output_dir/ \\
     "${params.run_name}" \\
     --pipeline-version "\$tag" \\
     --pipeline-commit-hash  \$commitid \\
     --run-date ${workflow.start.format("yyyy-MM-dd'T'HH:mm:ss")} \\
     --nextflow-params-fp temp_params.json
    """
}
