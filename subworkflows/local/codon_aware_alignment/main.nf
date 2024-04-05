include {COATI} from "../../../modules/local/coati/main"
include {COATI_PREPROCESS_READS} from "../../../modules/local/coati_preprocess/main"


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

    emit:
    COATI.out
    

}