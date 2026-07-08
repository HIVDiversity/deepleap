include { MERGE_BY_GROUP } from "./main"

workflow {
    def file_a = file("${launchDir}/test_data/inputs/sample_a.fasta")
    def file_b = file("${launchDir}/test_data/inputs/sample_b.fasta")

    // grp1 has two members (should merge); solo has one (should pass through)
    def input_ch = channel.from([
        [file_a, [sample_id: "a1", group: "grp1", num_seqs: 2, cap_name: "ABC"]],
        [file_b, [sample_id: "b1", group: "grp1", num_seqs: 3, cap_name: "ABC"]],
        [file_a, [sample_id: "solo", group: "solo", num_seqs: 4, cap_name: "XYZ"]],
    ])

    MERGE_BY_GROUP(input_ch)

    MERGE_BY_GROUP.out.merged_tuples.view { f, m ->
        "MERGED group=${m.group} sample_id=${m.sample_id} num_seqs=${m.num_seqs} file=${f.name}"
    }

    // Assert: exactly 2 output tuples; grp1 merged to num_seqs=5 sample_id=grp1;
    // solo untouched sample_id=solo num_seqs=4.
    MERGE_BY_GROUP.out.merged_tuples
        .toList()
        .subscribe { rows ->
            assert rows.size() == 2
            def byGroup = rows.collectEntries { f, m -> [m.group, m] }
            assert byGroup["grp1"].sample_id == "grp1"
            assert byGroup["grp1"].num_seqs == 5
            assert byGroup["solo"].sample_id == "solo"
            assert byGroup["solo"].num_seqs == 4
            println "ALL merge_by_group ASSERTIONS PASSED"
        }
}
