include {TRIM_SEQUENCES} from "./main"

workflow  {
   main:

   original_sequences = file("/home/dlejeune/masters/nf-test-data/test_trim_sequences/CAP344_2000-pool1_nicd.fasta") 
   trimmed_consensus = file("/home/dlejeune/masters/nf-test-data/test_trim_sequences/trimmed_consensus.fasta")
   
   meta = ["sample_id": "CAP344_2000-pool1_nicd" ]

   input_ch = channel.from([[original_sequences, trimmed_consensus, meta]])

    TRIM_SEQUENCES(
        input_ch
    )

    TRIM_SEQUENCES.out.view()
}