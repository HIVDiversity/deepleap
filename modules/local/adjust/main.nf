

process ADJUST{
    tag "$meta.sample_id"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.corrected.fasta"), val(meta), emit: sample_tuple

    script:

    """
    python /home/dlejeune/masters/codon_align/codon_adjust.py ${input_file} ${meta.sample_id}.corrected.fasta
    """
}