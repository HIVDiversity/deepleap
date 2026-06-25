# Getting Started
## Prerequisites
DeepLEAP is built using [Nextflow](https://www.nextflow.io/) version 25.04.2 which must be installed on your system, and depends upon a container runtime such as [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/docs/). Other containerization systems may work as long as they can convert Docker images to their own format.

### Nextflow Installation
Nextflow requires Java to be installed on your system. Thereafter, you can install Nextflow by running the following command in your terminal:
```bash
curl -s https://get.nextflow.io | bash
```
And you can check that this has been successful by running:
```bash
./nextflow run hello
```
Further information can be found in the [Nextflow documentation](https://www.nextflow.io/docs/latest/index.html).

### Container Runtime
Note, you only need to have one of these installed on your system.

#### Docker Installation
Instructions for installing Docker can be found on the [Docker website](https://docs.docker.com/engine/install/). You can check if Docker is installed correctly by running:
```bash
sudo docker run hello-world
```

#### Singularity Installation
You can find instructions for installing Singularity on the [Singularity website](https://docs.sylabs.io/guides/3.0/user-guide/installation.html). You can check if Singularity is installed correctly by running:
```bash
singularity run --containall library://sylabsed/examples/lolcow
```

## Installation
Simply clone this repository into the directory of your choice:
```bash
git clone git@github.com:HIVDiversity/deepleap.git
```
## Usage
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
- `--samplesheet`: Path to a CSV file containing sample information. See `sample_data/samplesheet.csv` for an example.
- `--reference_file`: Path to a FASTA file containing the reference sequence for alignment.
- `--aligner`: The alignment tool to use.
- `--region_of_interest`: The genomic region to focus on. This does not have to be in any format, and is largely present for legacy reasons.
- `--sample_base_dir`: Path to the directory containing input FASTA files. This is the directory where the files specified in the samplesheet are will be looked for. 
- `--skip_trim`: Optional flag to skip the trimming step. In this case it is necessary since the input files are already trimmed to the region of interest.
- `-profile`: Specifies the configuration profile to use. In this example, we use the `test` profile for testing purposes which will cap the memory usage to the maximum available on the machine and the `docker` profile to run the pipeline using Docker containers. You can also use the `singularity` profile if you prefer Singularity.
- `-c`: Specifies the path to the Nextflow configuration file. By default, Nextflow looks for a file named `nextflow.config` in the current directory, but the option is specified here for clarity.
- `-output-dir`: Path to the directory where output files will be saved.

### Outputs
The outputs of the pipeline will be saved in the directory specified by the `-output-dir` option. The structure of the output directory will be as follows:

```
testoutput/
├── amino_acid_alignments/
├── execution_report/
├── functional_filter
├── logs/
├── nucleotide_alignments/
├── rejected_sequences/
└── trimmed_sequences/
