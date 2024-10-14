process REVERSE_TRANSLATE{
    tag "$meta.sample_id"
    label "reverse_translate"

    input:
    tuple val(meta), path(aligned_aa_file), path(nt_file), path(name_file)
    

    output:
    tuple  path("*.fasta"), val(meta) , emit: sample_tuple

    script:

    """
    /usr/local/bin/reverse-translate \\
    -i ${aligned_aa_file} \\
    -n ${nt_file} \\
    -m ${name_file} \\
    -o ${meta.sample_id}.rev_trn.fasta
    """

}