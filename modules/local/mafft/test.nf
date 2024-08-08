nextflow.enable.dsl=2

include {MAFFT} from "./main"
include {MAFFT_ADD_PROFILE} from "./main"

workflow{

    main:

    read_file = file("/home/dlejeune/masters/nf-test-data/test_two_seqs.fa")

    file_one = file("/home/dlejeune/masters/nf-test-data/profile_align_test/al_file1.fasta")
    file_two = file("/home/dlejeune/masters/nf-test-data/profile_align_test/al_file2.fasta")
    file_three = file("/home/dlejeune/masters/nf-test-data/profile_align_test/al_file3.fasta")

    input_channel = channel.of(file_one, file_two, file_three)

    MAFFT_ADD_PROFILE(
        input_channel.collect()
    )


    // MAFFT(
    //     read_file
    // )
    

}