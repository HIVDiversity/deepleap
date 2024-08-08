process MAFFT{
    tag "TODO"
    container "dlejeune/mafft:7.525"

    input:
    path(input_file)

    output:
    path("*.mafft.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    mafft $input_file > ${prefix}.mafft.fasta
    """


}

process MAFFT_ADD{
    tag "TODO"
    container "dlejeune/mafft:7.525"

    input:
    path(input_file)
    path(ref_file)

    output:
    path("*.mafft.fasta"), emit: fasta

    script:

    prefix = input_file.baseName.tokenize('.')[0]

    """
    mafft --add $ref_file  $input_file > ${prefix}.ref.mafft.fasta
    """
}


process MAFFT_ADD_PROFILE{
    tag "TODO"
    container "dlejeune/mafft:7.525"

    input:
    val(input_files)

    output:
    path("output_file.fasta"), emit: fasta

    script:
    
    file_one = input_files[0]
    other_files = input_files[1..-1]
    

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