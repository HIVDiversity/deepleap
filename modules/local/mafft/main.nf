process MAFFT {
    tag "${meta.sample_id}"
    label "mafft"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.mafft.fasta"), val(meta), emit: sample_tuple

    script:

    """
    mafft --thread -1 ${task.ext.args} ${input_file} > ${meta.sample_id}.mafft.fasta
    """
}

process MAFFT_FAST_ALIGN {
    tag "${meta.sample_id}"
    label "mafft"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.mafft.fasta"), val(meta), emit: sample_tuple

    script:

    """
    mafft --thread -1 ${task.ext.args} ${input_file} > ${meta.sample_id}.mafft.fasta
    """
}

process MAFFT_ADD {
    tag "${meta.sample_id}"
    label "mafft"

    input:
    tuple path(input_file), val(meta)
    path ref_file

    output:
    tuple path("*.mafft.fasta"), val(meta), emit: sample_tuple

    script:
    """
    mafft --thread -1 --localpair --maxiterate 1000 --add ${ref_file}  ${input_file} > ${meta.sample_id}.ref.mafft.fasta
    """
}


process MAFFT_ADD_PROFILE {
    tag "${grouping_id}"
    label "mafft"

    input:
    tuple val(grouping_id), val(input_files), val(metadatas)

    output:
    tuple path("*.fasta"), val(grouping_id), emit: profile_alignment_tuple

    script:
    file_one = input_files[0]
    other_files = input_files[1..-1]
    def output_file = "CAP${grouping_id}.profile_aligned.fasta"

    bash_other_files = "(" + other_files.join(" ") + ")"

    """
    cp ${file_one} ${output_file};

    file_arr=${bash_other_files};

    for file in \${file_arr[@]};
    do
        if [[ -s \$file ]]
        then
            mafft --thread -1 --add \$file ${output_file} > temp_${output_file};
            rm ${output_file};
            mv temp_${output_file} ${output_file};
        else
            echo "The file \$file is empty" 1>&2;
        fi
    done
    """
}


process MAFFT_MERGE {
    tag "${grouping_id}"
    label "mafft"

    input:
    tuple val(grouping_id), path(alignment_file), path(merge_index)

    output:
    tuple path("*.fasta"), val(grouping_id), emit: merged_alignment

    script:
    """
    mafft --merge ${merge_index} ${alignment_file} > ${grouping_id}_merge-aln.fasta 
    """
}
