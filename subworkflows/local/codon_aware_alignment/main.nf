include {COATI} from "../../../modules/local/coati/main"
include {COATI_PREPROCESS_READS} from "../../../modules/local/coati_preprocess/main"
include {KCALIGN as KCALIGN_KALIGN} from "../../../modules/local/kcalign/main"
include {KCALIGN as KCALIGN_MUSCLE} from "../../../modules/local/kcalign/main"

workflow CODON_ALIGNMENT{
    take:
    input_file 
    reference_file

    main:


    input_file = file(input_file)

    COATI_PREPROCESS_READS(
        input_file,
        reference_file
    )

    files = COATI_PREPROCESS_READS.out.pre_processed_fasta.flatten()

    COATI(
        files
    )

    KCALIGN_KALIGN(
        input_file, 
        reference_file,
        "kalign"
    )

    KCALIGN_MUSCLE(
        input_file, 
        reference_file,
        "muscle"
    )

    emit:
    coati = COATI.out
    kalign_kcalign = KCALIGN_KALIGN.out
    muscle_kcalign = KCALIGN_MUSCLE.out


    

}