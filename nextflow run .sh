nextflow run \
    -c ./nextflow.config \
    -profile singularity\
    ./main.nf \
    --samplesheet /home/dlejeune/Documents/real_data/staging/first_two_caps/samplesheet.csv \
    --reference_file /home/dlejeune/Documents/real_data/hxb2-env.fasta \
    --run_name first_two_timepoints \
    --region_of_interest envelope-polyprotein \
    --aligner MAFFT \
    --sample_base_dir /home/dlejeune/Documents/real_data/staging/first_two_caps \
    --region_shorthand ENV \
    --preprocess CUSTOM \
    --slurm_queue Main \
    --ff_max_stop_pct 90\
    --max_memory 20 \
    --multi_timepoint_alignment
