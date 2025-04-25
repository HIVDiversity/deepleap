include { CONCAT_FASTA_FILES } from "./main"
workflow {

    def file_a = file("/home/dlejeune/masters/nf-test-data/test_concat_fasta/CAP001_1000.fasta")
    def file_b = file("/home/dlejeune/masters/nf-test-data/test_concat_fasta/CAP001_2000.fasta")

    def meta_a = ["sample_id": "CAP001_1000", "cap_name": "001"]
    def meta_b = ["sample_id": "CAP001_2000", "cap_name": "001"]

    def input_ch = channel
        .from([[file_a, meta_a], [file_b, meta_b]])
        .map { file, metadata ->
            [metadata['cap_name'], file]
        }
        .groupTuple()
        .map { cap_id, files ->

            return [files.collect(), cap_id]
        }



    CONCAT_FASTA_FILES(input_ch)

    CONCAT_FASTA_FILES.out.view()
}
