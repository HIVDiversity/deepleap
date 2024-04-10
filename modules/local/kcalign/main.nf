

process KCALIGN{
    tag "TODO"
    container "dlejeune/kc-align:0.0.1"
    publishDir "${params.outdir}/kcalign", mode: 'copy', saveAs: {filename -> "${method}.kcalign.fasta"}
    

    input:
    path(input_file)
    path(reference)
    val(method)

    output:
    path("*.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    python /usr/bin/kcalign/kcalign/cli.py --method $method \\
    --mode mixed \\
    --reference $reference \\
    --sequences $input_file

    """


}