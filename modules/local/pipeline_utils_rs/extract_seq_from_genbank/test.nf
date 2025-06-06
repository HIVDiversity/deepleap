include { EXTRACT_SEQ_FROM_GB } from './main'
workflow {
    def input_file = file("/home/dlejeune/masters/nf-test-data/test_whole_pipeline/hxb2_annotated.gb")
    def region_of_interest = "envelope-polyprotein"

    EXTRACT_SEQ_FROM_GB(
        input_file,
        region_of_interest,
    )

    EXTRACT_SEQ_FROM_GB.out.extracted_sequence_fasta.view()
}
