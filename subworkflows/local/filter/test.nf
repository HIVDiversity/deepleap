
include { FILTER } from './main'
workflow  {

    input_file_a = file("/home/dlejeune/masters/nf-test-data/aga_tests/input_a.fasta")
    meta_a = [sample_id: "ABC", cds_name:"7_envelope_polyprotein"]

    input_file_b = file("/home/dlejeune/masters/nf-test-data/aga_tests/input_b.fasta")
    
    meta_b = [sample_id: "DEF", cds_name:"7_envelope_polyprotein"]

    def genbankFile = file("/home/dlejeune/Documents/real_data/CAP257/aga/hxb2_annotated.gb")
    def genbankChannel = channel.value(genbankFile)

    sample_tuples = channel.of([input_file_a, meta_a], [input_file_b, meta_b])

    FILTER(
        sample_tuples,
        genbankChannel
    )


        
}