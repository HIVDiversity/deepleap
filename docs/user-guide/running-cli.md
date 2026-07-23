---
icon: lucide/terminal
---

# Running the CLI
## Prerequisites
You need to have installed the pipeline as described in [Installation](installation.md)
## First Run
The repository has a sample dataset in the `sample_data` directory which we can use to test the pipeline. Navigate to the `deepleap` directory, and run the following command, replacing `${deepleap_root}` with the path to the directory you cloned this repo to:

```bash
nextflow run -c nextflow.config main.nf \
--run_name testA \
--samplesheet ${deepleap_root}/sample_data/samplesheet.csv  \ 
--reference_file ${deepleap_root}/sample_data/hxb2_env.fasta \
--aligner MAFFT \
-profile test,docker \
--region_of_interest envelope-polyprotein \
--sample_base_dir ${deepleap_root}/sample_data/input \
-output-dir ./testoutput/ \
--skip_trim
```

!!! note

    Depending on your docker setup (if using docker), you may need to enter your sudo password. The prompt for this sometimes gets hidden by the rest of the Nextflow output, so be sure to check your terminal if the pipeline seems to hang. 



### Parameter explanation
- `--run_name`: A name for this pipeline run. Is used in logging and report generation.
- `--samplesheet`: Path to a CSV file containing sample information. See [Samplesheet Reference](../reference/samplesheet.md).
- `--reference_file`: Path to a FASTA file containing the reference sequence for alignment.
- `--aligner`: The alignment tool to use.
- `--region_of_interest`: The genomic region to focus on. This does not have to be in any format, and is largely present for legacy reasons.
- `--sample_base_dir`: Path to the directory containing input FASTA files. This is the directory where the files specified in the samplesheet are will be looked for. 
- `--skip_trim`: Optional flag to skip the trimming step. In this case it is necessary since the input files are already trimmed to the region of interest.
- `-profile`: Specifies the configuration profile to use. In this example, we use the `test` profile for testing purposes which will cap the memory usage to the maximum available on the machine and the `docker` profile to run the pipeline using Docker containers. You can also use the `singularity` profile if you prefer Singularity.
- `-c`: Specifies the path to the Nextflow configuration file. By default, Nextflow looks for a file named `nextflow.config` in the current directory, but the option is specified here for clarity.
- `-output-dir`: Path to the directory where output files will be saved.

### Samplesheet format

See the [Samplesheet Reference](../reference/samplesheet.md) for required and optional columns.

### Outputs
The outputs of the pipeline will be saved in the directory specified by the `-output-dir` option. The structure of the output directory will be as follows:

```
testoutput/
├── alignments/
│   ├── nucleotide_alignments/
│   ├── amino_acid_alignments/
│   └── profile_alignments/    # multi_timepoint_alignment only (deprecated)
├── functional_filter/
│   ├── reports/
│   ├── rejected_sequences/
│   ├── passed_sequences/
│   └── trim_stop/             # LENGTH_BASED_FILTERING only
├── preprocess/
│   └── trimmed_sequences/     # omitted if --skip_trim
├── phylogeny/                 # only if --build_phylogeny
│   ├── trees/
│   └── iqtree_files/
├── execution_report/          # legacy, being removed
├── logs/
└── pipeline_info/
```

See the [Output Reference](../reference/outputs.md) for what each directory contains.