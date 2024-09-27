process MAFFT{
    tag "$meta.sample_id"
    label "mafft"

    input:
    tuple path(input_file), val(meta)

    output:
    tuple path("*.mafft.fasta"), val(meta), emit: sample_tuple

    script:

    

    """
    mafft --threads -1 --localpair --maxiterate 1000 $input_file > ${meta.sample_id}.mafft.fasta
    """


}

process MAFFT_ADD{
    tag "$meta.sample_id"
    label "mafft"

    input:
    tuple path(input_file), val(meta)
    path(ref_file)

    output:
    tuple path("*.mafft.fasta"), val(meta), emit: sample_tuple

    script:
    """
    mafft --add $ref_file  $input_file > ${meta.sample_id}.ref.mafft.fasta
    """
}


process MAFFT_ADD_PROFILE{
    tag "TODO"
    label "mafft"

    input:
    val(input_files)

    output:
    path("output_file.fasta"), emit: fasta

    script:
    
    file_one = input_files[0]
    other_files = input_files[1..-1]
    
    println(file_one)
    println(other_files)

    bash_other_files = "(" + other_files.join(" ") + ")"

    """
    cp $file_one output_file.fasta;

    file_arr=$bash_other_files;

    for file in \${file_arr[@]};
    do
        mafft --add \$file output_file.fasta > temp_output_file.fasta;
        rm output_file.fasta;
        mv temp_output_file.fasta output_file.fasta;
    done
    """
}