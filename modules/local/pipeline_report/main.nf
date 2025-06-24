process PIPELINE_REPORT {
    input:
    path pre_files, stageAs: "pre_files/*"
    path post_files, stageAs: "post_files/*"
    path functional_filter_files, stageAs: "func_filter_files/*"

    output:
    path "output_dir/*"

    script:

    """
    generate-pipeline-report pre_files/ \\
     post_files/ \\
     func_filter_files/ \\
     ./output_dir/ \\
     "first_timepoints_v3_001" \\
     --pipeline-version "1.5.2" \\
     --pipeline-commit-hash ${workflow.commitId} \\
     --run-date ${workflow.start.format("yyyy-MM-dd'T'HH:mm:ss")}\\
    """
}
