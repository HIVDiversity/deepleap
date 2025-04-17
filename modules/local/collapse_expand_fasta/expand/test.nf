include { EXPAND } from "./main"

workflow {

    sequences = file("/home/dlejeune/masters/nf-test-data/test_expand/CAP409_2000-pool12_inqaba.collapsed.fasta")
    namefile = file("/home/dlejeune/masters/nf-test-data/test_expand/CAP409_2000-pool12_inqaba.namefile.json")

    meta = ["sample_id": "CAP409_2000-pool12_inqaba"]


    sequence_ch = channel.from([[sequences, meta]])
    name_ch = channel.from([[namefile, meta]])
    input_ch = sequence_ch.join(name_ch, by: 1).map { it -> [it[1], it[2], it[0]] }

    EXPAND(
        input_ch
    )

    EXPAND.out.sample_tuple.view()
}
