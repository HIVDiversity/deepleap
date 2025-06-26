include { MAFFT_ADD_PROFILE } from "../../modules/local/mafft/main"
include { CONCAT_JSON_FILES } from "../../modules/local/utils/concat_json/main"
include { CONCAT_FASTA_FILES } from "../../modules/local/utils/concat_fasta/main"
include { EXPAND } from "../../modules/local/collapse_expand_fasta/expand/main"
include { COLLAPSE } from "../../modules/local/collapse_expand_fasta/collapse/main"
include { REVERSE_TRANSLATE } from "../../modules/local/pipeline_utils_rs/reverse-translate/main"
include { REMOVE_REFERENCE } from "../../modules/local/utils/remove_reference/main"

workflow MULTI_TIMEPOINT_ALIGNMENT {
    take:
    sample_tuples // file, meta
    nt_sample_tuples // file(nt), meta
    name_tuples // file(json), meta

    main:

    // TODO: We make sure that the channels that only have a single file, ie the files that don't get sent through the profile alignment
    // get merged back into the queue such that they can be all output into the same directory...

    // This step converts [[file, meta], [file, meta]] into
    // [CAPXYZ, [file_0, file_1, file_2], metadata]
    // With file_i where i is the visit code
    // It also ensures that participants with only one timepoint skip the whole process of alignment

    def grouped_files = sample_tuples
        .map { file, metadata ->
            [metadata['cap_name'], file, metadata]
        }
        .groupTuple()
        .map { cap_id, files, metadata ->
            // Create pairs of [file, metadata] for sorting
            def pairs = files.indices.collect { i -> [files[i], metadata[i]] }

            // Sort pairs by visit_id
            def sorted_pairs = pairs.sort { a, b -> a[1]['visit_id'] <=> b[1]['visit_id'] }

            // Extract sorted files and metadata
            def sorted_files = sorted_pairs.collect { it[0] }
            def sorted_metadata = sorted_pairs.collect { it[1] }

            return [cap_id, sorted_files, sorted_metadata]
        }
        .branch { cap_id, sorted_files, _sorted_metadata ->
            multi_timepoints: sorted_files.size() > 1
            single_timepoints: true
        }

    // We need to remove the reference from the non-first samples
    def ch_split_timepoints = grouped_files.multi_timepoints.multiMap { cap_id, sorted_files, metadata ->
        first_sample: [cap_id, sorted_files[0], metadata]
        other_samples: [cap_id, sorted_files[1..-1], metadata]
    }



    REMOVE_REFERENCE(ch_split_timepoints.other_samples)

    def ch_add_profile_input = ch_split_timepoints.first_sample
        .join(REMOVE_REFERENCE.out.fasta_tuple, by: 0)
        .map { cap_id, first_file, meta_2, file_list, _meta_1 ->
            [cap_id, [first_file] + file_list, meta_2]
        }



    def ch_single_timepoints = grouped_files.single_timepoints.map { cap_id, sorted_files, _sorted_metadata -> [sorted_files[0], cap_id] }
    MAFFT_ADD_PROFILE(
        ch_add_profile_input
    )

    // We need to concatenate the JSON namefiles so that we can expand the profile alignments
    // This converts the name_flie tuples from [[file, meta], [file, meta]] into 
    // [[file, file, file], CAPID]

    def json_input_ch = name_tuples
        .map { file, metadata ->
            [metadata['cap_name'], file]
        }
        .groupTuple()
        .map { cap_id, files ->

            return [files.collect(), cap_id]
        }

    CONCAT_JSON_FILES(
        json_input_ch
    )

    // We also need to concatenate the various visit nucleotide files so that the 
    // expansion and reverse-translation can work
    def nt_input_ch = nt_sample_tuples
        .map { file, metadata ->
            [metadata['cap_name'], file]
        }
        .groupTuple()
        .map { cap_id, files ->

            return [files.collect(), cap_id]
        }
    CONCAT_FASTA_FILES(
        nt_input_ch
    )


    def expand_input_ch = MAFFT_ADD_PROFILE.out.profile_alignment_tuple
        .mix(ch_single_timepoints)
        .join(CONCAT_JSON_FILES.out.json_tuple, by: 1)
        .map { grouping_key, profile_file, json_files -> [profile_file, json_files, ["sample_id": grouping_key]] }

    EXPAND(
        expand_input_ch
    )

    def reverse_translate_input_ch = CONCAT_FASTA_FILES.out.fasta_tuple
        .map { fasta_file, grouping_key -> [fasta_file, ["sample_id": grouping_key]] }
        .join(EXPAND.out.sample_tuple, by: 1)
        .map { meta, fasta_file, expanded_file -> [expanded_file, fasta_file, meta] }

    REVERSE_TRANSLATE(
        reverse_translate_input_ch
    )

    emit:
    sample_tuples_prof_aln_nt = MAFFT_ADD_PROFILE.out.profile_alignment_tuple
}
