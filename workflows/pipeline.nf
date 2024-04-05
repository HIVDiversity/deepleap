include {CODON_ALIGNMENT} from "../subworkflows/local/codon_aware_alignment/main"


workflow HIV_SEQ_PIPELINE{

    CODON_ALIGNMENT()

}