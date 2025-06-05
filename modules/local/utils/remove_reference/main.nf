process REMOVE_REFERENCE {
    input:
    tuple val(cap_id), val(fasta_files), val(meta)

    output:
    tuple val(cap_id), path("*.fasta"), val(meta), emit: fasta_tuple

    script:
    // Incredibly scuffed bash command. In essence, for all the files passed to it, removes sequences matching the 
    // name of the reference sequence in the meta dictionary.
    bash_files = "(" + fasta_files.join(" ") + ")"
    """
    file_arr=${bash_files};
    for file in \${file_arr[@]};
    do
    filename=\${file##*/}
    awk '/^>/{keep = (\$1 != ">${meta.ref_seq_name}")} keep' \$file > \${filename%.*}_noref.fasta
    done
    """
}
