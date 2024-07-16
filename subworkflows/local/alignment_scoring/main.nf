nextflow.enable.dsl=2


include {COLLAPSE} from "../../../modules/local/aligment_utils/main.nf"


workflow ALIGNER_COMPARISON{
    take:
    run // path(input file), val(meta)
    

    main:

    run.map {run_trim(it[1])}.set{run_trim_flag}

    println run_trim_flag

    run.branch{
        collapse_ch: it[1]["pre"]["collapse"] == true
        carry_through: it[1]["pre"]["collapse"] == false
    }.set{sample_channel}

    COLLAPSE(
        sample_channel.collapse_ch
    )

    // Either: Collapse.out empty, carry_through not empty
    // OR: Collapse.out not empty, carry_through empty
    sample_channel = COLLAPSE.out.mix(sample_channel.carry_through).branch{
        reverse_ch: it[1]["pre"]["reverse"] == true
        carry_through: it[1]["pre"]["reverse"] == false
    }



    REVERSE(
        sample_channel.reverse_ch
    )





    

    // run.map{it[1]}.filter {it.meta.run_id == 3}.view()

    // At this point we want to pass the input tuple into the first tool, only if meta says we should

    // input_file = file(input_file)

    // // COATI_PREPROCESS_READS(
    // //     input_file,
    // //     reference_file
    // // )

    // // files = COATI_PREPROCESS_READS.out.pre_processed_fasta.flatten()

    // // COATI(
    // //     files
    // // )

    // KCALIGN_KALIGN(
    //     input_file, 
    //     reference_file,
    //     "kalign"
    // )

    // VIRULIGN(
    //     input_file,
    //     reference_file
    // )

    // PRANK(
    //     input_file
    // )

    // MACSE(
    //     input_file
    // )



    // emit:
    // coati = COATI.out
    // kalign_kcalign = KCALIGN_KALIGN.out
    // muscle_kcalign = KCALIGN_MUSCLE.out
    // virulign = VIRULIGN.out.fasta
    // macse = MACSE.out.nt_fasta

    

}

def run_trim(meta){

    return meta.pre.trim
    
}

def run_collapse(run_tuple){
    def meta = run_tuple[1]

    return meta.pre.collapse
}