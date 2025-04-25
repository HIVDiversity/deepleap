include { MAFFT_ADD_PROFILE } from "../../../modules/local/mafft/main"

workflow MULTI_TIMEPOINT_ALIGNMENT {
    take:
    sample_tuples // file, meta

    main:
    // TODO: Add a step to join namefiles together so that uncollapsing is possible
    // TODO: Also have a step to concat all the pre-nt files so that reverse-translating is possible
    def input_ch = sample_tuples
        .map { file, metadata ->
            [metadata['cap_name'], file, metadata]
        }
        .groupTuple()
        .map { cap_id, files, metadatas ->
            // Create pairs of [file, metadata] for sorting
            def pairs = files.indices.collect { i -> [files[i], metadatas[i]] }

            // Sort pairs by visit_id
            def sorted_pairs = pairs.sort { a, b -> a[1]['visit_id'] <=> b[1]['visit_id'] }

            // Extract sorted files and metadata
            def sorted_files = sorted_pairs.collect { it[0] }
            def sorted_metadata = sorted_pairs.collect { it[1] }

            return [cap_id, sorted_files, sorted_metadata]
        }

    input_ch.view()

    MAFFT_ADD_PROFILE(
        input_ch
    )

    emit:
    profile_aligment = MAFFT_ADD_PROFILE.out.profile_alignment_tuple
}
