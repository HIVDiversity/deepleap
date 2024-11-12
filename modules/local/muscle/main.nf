process MUSCLE{
    tag "$meta.sample_id"
    label "muscle"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.muscle.aln.fasta"), val(meta), emit: sample_tuple

    script:

    """
    muscle -align $input_file -output ${meta.sample_id}.muscle.aln.fasta
    """


}


process MUSCLE_SUPER_FIVE{
    tag "$meta.sample_id"
    label "muscle"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.muscle.aln.fasta"), val(meta), emit: sample_tuple

    script:

    """
    muscle -super5 ${input_file} -output ${meta.sample_id}.muscle.aln.fasta
    """


}