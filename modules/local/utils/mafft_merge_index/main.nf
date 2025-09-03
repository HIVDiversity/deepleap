process MAKE_MAFFT_MERGE_FILES {
    tag "${grouping_id}"
    label "mafft"

    input:
    tuple val(grouping_id), val(input_files), val(metadatas)

    output:
    tuple path("*.fasta"), path("*.txt"), val(grouping_id), emit: mafft_merge_files

    script:
    """
    #!/usr/bin/env python
    from pathlib import Path

    def read_fasta(filepath: Path) ->:
        fasta_string_lines = open(filepath, "r").readlines()
        sequences = {}
        header = ""
        for line in fasta_string_lines:
            line = line.strip()
            if line.startswith(">"):
                header = line.strip().strip(">")
                if header in sequences:
                    print(
                        f"There is already a line with the header {header} and it will be overwritten"
                    )
                sequences[header] = ""
            else:
                sequences[header] += line.strip()

        return sequences

    alignments = Path("")
    merged_file = Path(group + "_merged.fasta")
    index_file = Path(group + "_index.txt")
    all_counts = []
    count = 1

    with merged_file.open("w") as fh:
        for msa_path in alignments.glob("*.fasta"):
            count_line = []
            msa = read_fasta(msa_path)
            for seq_id, seq in msa.items():
                fh.write(f">{seq_id}\\n{seq}\\n")
                count_line.append(count)
                count += 1
        all_counts.append(count_line)
    
    with index_file.open("w") as ifh:
        for line in all_counts:
            ifh.write(" ".join([str(x) for x in line]))
            ifh.write("\n")
    """
}
