include { parseSampleSheet ; mergeGroupMeta ; toBool } from './utils'

workflow {
    // --- toBool ---
    assert toBool(null) == false
    assert toBool("") == false
    assert toBool("false") == false
    assert toBool("FALSE") == false
    assert toBool("0") == false
    assert toBool("no") == false
    assert toBool("true") == true
    assert toBool("TRUE") == true
    assert toBool("1") == true
    assert toBool("yes") == true

    // --- mergeGroupMeta ---
    def metas = [
        [sample_id: "m1", group: "G", num_seqs: 3, cap_name: "ABC", visit_id: "0"],
        [sample_id: "m2", group: "G", num_seqs: 2, cap_name: "ABC", visit_id: "0"],
    ]
    def merged = mergeGroupMeta(metas)
    assert merged.sample_id == "G"
    assert merged.group == "G"
    assert merged.num_seqs == 5
    assert merged.cap_name == "ABC"
    assert merged.visit_id == "0"

    // first-value-with-warn when members disagree (visit_id differs)
    def metas2 = [
        [sample_id: "m1", group: "G", num_seqs: 1, visit_id: "0"],
        [sample_id: "m2", group: "G", num_seqs: 1, visit_id: "1"],
    ]
    def merged2 = mergeGroupMeta(metas2)
    assert merged2.visit_id == "0"   // first wins

    // --- parseSampleSheet: group fallback + boolean coercion ---
    def sheet = file("${launchDir}/bin/test_data/mini_samplesheet.csv")
    def rows = parseSampleSheet(sheet, file("${launchDir}/test_data/inputs"), [:])
    def byId = rows.collectEntries { f, m -> [m.sample_id, m] }

    // row with no group column value → group defaults to sample_id
    assert byId["sampleA"].group == "sampleA"
    assert byId["sampleA"].skip_trim == false
    assert byId["sampleA"].skip_filter == false

    // row with explicit group + skips
    assert byId["sampleB"].group == "grp1"
    assert byId["sampleB"].skip_trim == true
    assert byId["sampleB"].skip_filter == false

    println "ALL bin/test_utils.nf ASSERTIONS PASSED"
}
