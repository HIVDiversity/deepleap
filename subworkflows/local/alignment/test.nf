include {CODON_ALIGNMENT} from "./main"


workflow{

    input_file_a = file("/home/dlejeune/masters/nf-test-data/test_alignment/ABC.collapsed.fasta")
    namefile_a = file("/home/dlejeune/masters/nf-test-data/test_alignment/ABC.names.json")
    meta_a = [sample_id: "ABC"]

    input_file_b = file("/home/dlejeune/masters/nf-test-data/test_alignment/DEF.collapsed.fasta")
    namefile_b = file("/home/dlejeune/masters/nf-test-data/test_alignment/DEF.names.json")
    meta_b = [sample_id: "DEF"]

    sample_tuples = channel.of([input_file_a, meta_a], [input_file_b, meta_b])
    namefile_tuples = channel.of([namefile_a, meta_a], [namefile_b, meta_b])
    

    CODON_ALIGNMENT(
        sample_tuples,
        namefile_tuples
    )


    CODON_ALIGNMENT.out.view()

}