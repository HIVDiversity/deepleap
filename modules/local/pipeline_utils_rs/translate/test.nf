include { TRANSLATE } from "./main"

workflow {

    sequences = file("/home/dlejeune/masters/nf-test-data/test_translate/CAP409_2000-pool12_inqaba_CDS_NT_envelope-polyprotein.fasta")


    meta = ["sample_id": "CAP409_2000-pool12_inqaba"]

    input_ch = channel.from([[sequences, meta]])

    TRANSLATE(
        input_ch
    )

    TRANSLATE.out.view()
}
