include { PIPELINE_REPORT } from "./main"

workflow {

    def file_one = file("/home/dlejeune/masters/nf-test-data/test_report/samples/CAP001_1000.fasta")
    def file_two = file("/home/dlejeune/masters/nf-test-data/test_report/samples/CAP001_2000.fasta")

    def file_one_results = file("/home/dlejeune/masters/nf-test-data/test_report/results/CAP001_1000.reverse_translated.fasta")
    def file_two_results = file("/home/dlejeune/masters/nf-test-data/test_report/results/CAP001_2000.reverse_translated.fasta")

    def file_one_filter = file("/home/dlejeune/masters/nf-test-data/test_report/filter_report/CAP001_1000.functional_report.csv")
    def file_two_filter = file("/home/dlejeune/masters/nf-test-data/test_report/filter_report/CAP001_2000.functional_report.csv")



    def meta_one = ["sample_id": "CAP001_1000", visit_id: "1000", cap_name: "CAP001"]
    def meta_two = ["sample_id": "CAP001_2000", visit_id: "2000", cap_name: "CAP001"]


    def input_files_list = [
        [file_one, meta_one],
        [file_two, meta_two],
    ]

    def output_files_list = [
        [file_one_results, meta_one],
        [file_two_results, meta_two],
    ]

    def report_file_list = [
        [file_one_filter, meta_one],
        [file_two_filter, meta_two],
    ]

    input_channel = channel.from(input_files_list)
    output_channel = channel.from(output_files_list)
    report_channel = channel.from(report_file_list)

    PIPELINE_REPORT(
        input_channel.map { file, _meta -> file }.collect(),
        output_channel.map { file, _meta -> file }.collect(),
        report_channel.map { file, _meta -> file }.collect(),
    )

    PIPELINE_REPORT.out.view()
}
