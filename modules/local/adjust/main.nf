

process ADJUST{
    tag "$meta.sample_id"
    label "codon_adjust"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.corrected.fasta"), val(meta), emit: sample_tuple

    script:

    """
    python /app/codon_adjust.py ${input_file} ${meta.sample_id}.corrected.fasta
    """
}