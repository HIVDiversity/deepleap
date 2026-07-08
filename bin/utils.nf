def toBool(value) {
    if (value == null) {
        return false
    }
    def s = value.toString().trim().toLowerCase()
    return s in ["true", "1", "yes"]
}

def mergeGroupMeta(metas) {
    def group = metas[0].group
    def merged = [:]

    // Start from the first member, take-first for every key.
    metas[0].each { k, v -> merged[k] = v }

    // Warn on disagreement for non-summed, non-identity keys.
    def skipKeys = ["num_seqs", "sample_id", "group"]
    metas[0].keySet().each { k ->
        if (k in skipKeys) {
            return
        }
        def distinct = metas.collect { it[k] }.unique()
        if (distinct.size() > 1) {
            log.warn("Group '${group}': members disagree on '${k}' (${distinct}); keeping first value '${merged[k]}'.")
        }
    }

    merged["sample_id"] = group
    merged["group"] = group
    merged["num_seqs"] = metas.sum { (it.num_seqs ?: 0) as int }
    return merged
}

def parseSampleSheet(samplesheet, sampleDir, otherMetadata) {
    def output_list = []

    samplesheet
        .splitCsv(header: true)
        .each { entry ->
            def new_output = []

            def filename = entry["filename"]
            def samplePath = sampleDir.resolve(filename)

            new_output.add(file(samplePath))
            entry = entry + otherMetadata
            entry["samplePath"] = file(samplePath)

            // Group defaults to sample_id when the column is absent or blank.
            def rawGroup = entry["group"]
            if (rawGroup == null || rawGroup.toString().trim() == "") {
                entry["group"] = entry["sample_id"]
            }
            else {
                entry["group"] = rawGroup.toString().trim()
            }

            // Coerce skip flags to booleans (absent/blank -> false).
            entry["skip_trim"] = toBool(entry["skip_trim"])
            entry["skip_filter"] = toBool(entry["skip_filter"])

            if (!entry.containsKey("num_seqs")) {
                def num_seqs = 0
                samplePath.eachLine { str ->
                    if (str.startsWith(">")) {
                        num_seqs += 1
                    }
                }

                entry["num_seqs"] = num_seqs
            }

            new_output.add(entry)

            output_list.add(new_output)
        }

    return output_list
}
