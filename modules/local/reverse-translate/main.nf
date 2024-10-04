process REVERSE_TRANSLATE{
    tag "$meta.sample_id"
    label "reverse_translate"

    input:
    tuple val(meta), path(aligned_aa_file), path(nt_file)
    

    output:
    tuple  path("*.fasta"), val(meta) , emit: sample_tuple

    script:

    """
    /usr/local/bin/reverse-translate ${aligned_aa_file} ${nt_file} ${meta.sample_id}.rev_trn.fasta
    """

}