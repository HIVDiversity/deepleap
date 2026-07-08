include { CONCAT_FASTA_FILES } from "./main"

workflow {
    def file_a = file("${launchDir}/test_data/inputs/sample_a.fasta")
    def file_b = file("${launchDir}/test_data/inputs/sample_b.fasta")

    def input_ch = channel
        .from([[file_a, "grp1"], [file_b, "grp1"]])
        .map { f, g -> [g, f] }
        .groupTuple()
        .map { g, files -> [files, g] }

    CONCAT_FASTA_FILES(input_ch)

    CONCAT_FASTA_FILES.out.fasta_tuple.view { path, g ->
        assert path.name == "grp1_merged.fasta"
        "OK concat produced ${path.name} for group ${g}"
    }
}
