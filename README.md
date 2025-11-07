
# DeepLEAP

DeepLEAP is a [Nextflow](https://github.com/nextflow-io/nextflow) pipeline that trims, filters and aligns long-read nucleotide sequences. Although specifically designed for HIV-1, it can be configured to work with data from other organisms.

## Usage

### Requirements

DeepLEAP is composed of a core Nextflow pipeline that depends on various third-party tools packaged in Docker containers. To run the pipeline, you must have [Nextflow v25.04.2](https://nextflow.io/docs/latest/) installed on your system, as well as [Docker](https://docs.docker.com/) or [Singularity](https://sylabs.io/docs/).

### Installation

To get started, clone this repository into the directory of your choice:

```bash
git clone git@github.com:HIVDiversity/deepleap.git
```

Then, navigate to the `deepleap` directory, and you're ready to run the pipeline.

### Running the Pipeline





