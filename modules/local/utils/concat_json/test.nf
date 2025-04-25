include { CONCAT_JSON_FILES } from "./main"

workflow {
    def file_a = file("/home/dlejeune/masters/nf-test-data/test_concat_json/json_a.json")
    def file_b = file("/home/dlejeune/masters/nf-test-data/test_concat_json/json_b.json")

    def meta_a = ["sample_id": "001_001", "cap_name": "001"]
    def meta_b = ["sample_id": "001_002", "cap_name": "001"]

    def input_ch = channel
        .from([[file_a, meta_a], [file_b, meta_b]])
        .map { file, metadata ->
            [metadata['cap_name'], file]
        }
        .groupTuple()
        .map { cap_id, files ->

            return [files.collect(), cap_id]
        }



    CONCAT_JSON_FILES(input_ch)

    CONCAT_JSON_FILES.out.view()
}
