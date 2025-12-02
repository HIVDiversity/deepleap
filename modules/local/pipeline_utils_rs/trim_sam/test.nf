include { TRIM_SAM } from "./main"

workflow {

    sam_file = file("/home/dlejeune/masters/thesis-data/trim_test/data/outputs/testcase_003_minimap.sam")
    from = 6225
    to = 8795


    meta = ["sample_id": "CAP344_2000-pool1_nicd"]

    input_ch = channel.from([[sam_file, meta]])
    coord_ch = channel.of([from, to])

    TRIM_SAM(
        input_ch,
        coord_ch,
    )

    TRIM_SAM.out.view()
}
