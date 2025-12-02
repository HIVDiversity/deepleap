include { MINIMAP_TWO } from "./main"

workflow {

    input_file = file("/home/dlejeune/masters/thesis-data/trim_test/data/inputs/HIV1_SFL_2018_genome_DNA.fasta")
    ref = file("/home/dlejeune/masters/thesis-data/trim_test/data/references/hxb2-env.fasta")


    meta = ["sample_id": "CAP344_2000-pool1_nicd"]

    input_ch = channel.from([[input_file, meta]])
    ref_ch = channel.of(ref)


    MINIMAP_TWO(
        input_ch,
        ref_ch,
    )

    MINIMAP_TWO.out.view()
}
