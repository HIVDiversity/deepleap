process MUSCLE {
    tag "${meta.sample_id}"
    label "muscle"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.muscle.aln.fasta"), val(meta), emit: sample_tuple

    script:
    """
    #!/bin/bash
    
    # We need to check if the input file contains two or more sequences, otherwise MUSCLE
    # throws an error. We just output the single file in that case. 
    
    numseqs=\$(grep ">" ${input_file} | wc -l)
    echo \$numseqs

    if [ "\$numseqs" -ge "2" ]; then
        echo "File contains 2 or more sequences. Proceeding to use MUSCLE"
        muscle -align ${input_file} -output ${meta.sample_id}.muscle.aln.fasta
    else
        echo "File contains fewer than 2 sequences. Outputting file as found."
        cp ${input_file} ${meta.sample_id}.muscle.aln.fasta
    fi
    """
}


process MUSCLE_SUPER_FIVE {
    tag "${meta.sample_id}"
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
