include {GET_CONSENSUS} from "./main"

workflow  {
   main:

   input_file = file("/home/dlejeune/masters/nf-test-data/test_get_consensus/CAP344_2000-pool1_nicd.aln.fasta") 
   meta = ["sample_id": "CAP344_2000-pool1_nicd" ]

   input_ch = channel.from([[input_file, meta]])

    GET_CONSENSUS(
        input_ch
    )

    GET_CONSENSUS.out.view()
}