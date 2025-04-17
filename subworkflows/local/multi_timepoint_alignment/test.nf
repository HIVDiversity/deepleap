include { MULTI_TIMEPOINT_ALIGNMENT } from "./main"
workflow {
    def file_one = file("/home/dlejeune/masters/nf-test-data/profile_align_test/al_file1.fasta")
    def file_two = file("/home/dlejeune/masters/nf-test-data/profile_align_test/al_file2.fasta")
    def file_three = file("/home/dlejeune/masters/nf-test-data/profile_align_test/al_file3.fasta")

    def meta_one = ["sample_id": "TEST_001", visit_id: "1000"]
    def meta_two = ["sample_id": "TEST_001", visit_id: "100"]
    def meta_three = ["sample_id": "TEST_001", visit_id: "500"]

    def files_list = [
        [file_one, meta_one],
        [file_two, meta_two],
        [file_three, meta_three],
    ]

    def file_ch = channel.from(files_list)

    def input_ch = file_ch
        .map { file, metadata ->
            [metadata['sample_id'], file, metadata]
        }
        .groupTuple()
        .map { sample_id, files, metadatas ->
            // Create pairs of [file, metadata] for sorting
            def pairs = files.indices.collect { i -> [files[i], metadatas[i]] }
            // Sort pairs by visit_id
            def sorted_pairs = pairs.sort { a, b -> a[1]['visit_id'] <=> b[1]['visit_id'] }
            // Extract sorted files and metadata
            def sorted_files = sorted_pairs.collect { it[0] }
            def sorted_metadata = sorted_pairs.collect { it[1] }

            return [sample_id, sorted_files, sorted_metadata]
        }

    MULTI_TIMEPOINT_ALIGNMENT(
        input_ch
    )
}
