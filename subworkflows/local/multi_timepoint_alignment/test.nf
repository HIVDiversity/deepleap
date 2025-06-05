include { MULTI_TIMEPOINT_ALIGNMENT } from "./main"
workflow {
    def file_one = file("/home/dlejeune/masters/nf-test-data/profile_align_test/al_file1.fasta")
    def file_two = file("/home/dlejeune/masters/nf-test-data/profile_align_test/al_file2.fasta")
    def file_three = file("/home/dlejeune/masters/nf-test-data/profile_align_test/al_file3.fasta")
    def file_one_nt = file("/home/dlejeune/masters/nf-test-data/profile_align_test/ua_file1.fasta")
    def file_two_nt = file("/home/dlejeune/masters/nf-test-data/profile_align_test/ua_file2.fasta")
    def file_three_nt = file("/home/dlejeune/masters/nf-test-data/profile_align_test/ua_file3.fasta")
    def empty_json_file = file("/home/dlejeune/masters/nf-test-data/profile_align_test/temp_json.json")

    def meta_one = ["sample_id": "TEST_001", visit_id: "1000", cap_name: "TEST"]
    def meta_two = ["sample_id": "TEST_001", visit_id: "100", cap_name: "TEST"]
    def meta_three = ["sample_id": "TEST_001", visit_id: "500", cap_name: "TEST2"]

    def files_list = [
        [file_one, meta_one],
        [file_two, meta_two],
        [file_three, meta_three],
    ]

    def file_ch = channel.from(files_list)
    def sample_nt_tuples = channel.from([[file_one_nt, meta_one], [file_two_nt, meta_two], [file_three_nt, meta_three]])
    def sample_name_tuples = channel.from([[empty_json_file, meta_one], [empty_json_file, meta_two], [empty_json_file, meta_three]])


    MULTI_TIMEPOINT_ALIGNMENT(
        file_ch,
        sample_nt_tuples,
        sample_name_tuples,
    )
}
