include { CONCAT_FASTA_FILES } from "../../../modules/local/utils/concat_fasta/main"
include { mergeGroupMeta } from "../../../bin/utils"

workflow MERGE_BY_GROUP {
    take:
    sample_tuples // channel of [file, meta]; meta has `group`

    main:
    // Collect each group's files and metas together.
    def grouped = sample_tuples
        .map { f, m -> [m.group, f, m] }
        .groupTuple()
        .branch { g, files, metas ->
            single: files.size() == 1
            multi: files.size() > 1
        }

    // Singletons pass straight through, untouched.
    def singles = grouped.single.map { g, files, metas -> [files[0], metas[0]] }

    // Multi-member groups: concatenate files, rebuild one meta.
    def to_concat = grouped.multi.map { g, files, metas -> [files, g] }
    CONCAT_FASTA_FILES(to_concat)

    def merged_meta = grouped.multi.map { g, files, metas -> [g, mergeGroupMeta(metas)] }

    def merged = CONCAT_FASTA_FILES.out.fasta_tuple
        .map { path, g -> [g, path] }
        .join(merged_meta)
        .map { g, path, meta -> [path, meta] }

    emit:
    merged_tuples = singles.mix(merged)
}
