process COATI_PREPROCESS_READS{
    container "dlejeune/coati-utils:latest"
    input:
    path(sample_file)
    path(reference_file)


    output:
    path("*.pre_processed.fasta"), emit: pre_processed_fasta

    script:

    """
    python /usr/src/coati_utils/src/coati_utils/cli.py preprocess --input-file $sample_file \\
    --reference-file $reference_file \\
    --suffix .pre_processed.fasta
    """



    



}