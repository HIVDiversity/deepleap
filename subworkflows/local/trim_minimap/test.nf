include { TRIM_MINIMAP } from "./main.nf"
workflow {
    input_file = file("/home/dlejeune/masters/thesis-data/trim_test/data/inputs/HIV1_SFL_2018_genome_DNA.fasta")
    ref = file("/home/dlejeune/masters/thesis-data/trim_test/data/references/hxb2-env.fasta")
    from = 6225
    to = 8795

    meta = ["sample_id": "CAP344_2000-pool1_nicd"]

    input_ch = channel.from([[input_file, meta]])
    ref_ch = channel.of(ref)

    coord_ch = channel.of([from, to])

    TRIM_MINIMAP(
        input_ch,
        ref_ch,
        coord_ch,
    )

    TRIM_MINIMAP.out.preprocessed_nt_seqs.view()
}
