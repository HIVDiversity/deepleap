include {CODON_ALIGNMENT} from "../subworkflows/local/codon_aware_alignment/main"


workflow HIV_SEQ_PIPELINE{

    input_file = file(params.input_file)
    reference = file(params.reference)

    CODON_ALIGNMENT(
        input_file,
        reference
    )

}