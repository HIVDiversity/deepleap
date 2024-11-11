process MUSCLE{
    tag "$meta.sample_id"
    container "dlejeune/muscle:5.1.0"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.mafft.fasta"), val(meta), emit: sample_tuple

    script:

    """
    muscle -align $input_file -output ${meta.sample_id}.muscle.aln.fasta
    """


}