---
icon: lucide/arrow-down-to-line
---

# Installation
DeepLEAP must be installed locally (or on an HPC) to be used.

## Prerequisites
 
You need two things before running DeepLEAP:
 
| Requirement | Version | Notes |
|---|---|---|
| [Nextflow](https://www.nextflow.io/) | ≥ 25.10.0 | Requires Java — see Nextflow's docs |
| Container runtime | — | Docker or Singularity (see below) |
 
No other local software installation is required. All pipeline tools run inside containers.
 
!!! note "Using the frontend?"
    If you plan to use DeepLEAP through the web frontend rather than the command line,
    follow the [Frontend Guide](frontend.md) instead — it has its own installation steps.
 
---
 
## 1. Install Nextflow
 
Nextflow requires Java. For Java installation guidance, refer to the
[Nextflow documentation](https://www.nextflow.io/docs/latest/install.html).
 
Once Java is available, install Nextflow by running:
 
```bash
curl -s https://get.nextflow.io | bash
```
 
This downloads a `nextflow` executable into your current directory. Move it somewhere on
your `PATH` (e.g. `~/bin` or `/usr/local/bin`) so it is available system-wide:
 
```bash
mv nextflow ~/bin/
```
 
Verify the installation:
 
```bash
nextflow run hello
```
 
You should see a short "Hello World" workflow execute successfully.
 
---
 
## 2. Install a Container Runtime
 
DeepLEAP has been tested with **Docker** and **Singularity**. You only need one.
 
=== "Docker"
 
    Install Docker by following the instructions for your operating system on the
    [Docker website](https://docs.docker.com/engine/install/).
 
    Verify the installation:
 
    ```bash
    sudo docker run hello-world
    ```
 
    !!! tip "Running without sudo"
        On Linux, Docker commands require `sudo` by default. If you would prefer to run
        without it, follow the
        [post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/)
        in the Docker docs to add your user to the `docker` group.
 
=== "Singularity"
 
    Install Singularity by following the instructions on the
    [Singularity website](https://docs.sylabs.io/guides/3.0/user-guide/installation.html).
 
    Verify the installation:
 
    ```bash
    singularity run --containall library://sylabsed/examples/lolcow
    ```
 
=== "Apptainer / other runtimes"
 
    Apptainer is architecturally very similar to Singularity and may work with DeepLEAP,
    but it has not been formally tested. Use at your own discretion.
 
    Other container runtimes (Podman, Charliecloud, etc.) are present in the Nextflow
    configuration but are equally untested.
 
!!! warning "HPC clusters"
    On HPC systems such as ilifu or UCT's hex cluster, a container runtime is almost
    always available as an environment module. Check with your system administrator before
    attempting to install one yourself:
 
    ```bash
    module avail singularity
    ```
 
!!! warning "Apple Silicon (ARM) machines"
    DeepLEAP has not been tested on Apple Silicon (M-series) Macs. It may work via
    Docker's `linux/amd64` emulation layer, but this is unsupported.
 
---
 
## 3. Get the Pipeline
 
Clone the repository and check out the latest versioned release. First, find the most
recent tag:
 
```bash
git clone https://github.com/HIVDiversity/deepleap.git
cd deepleap
git tag --sort=-version:refname | head -5
```
 
Then check out the release you want (replace `vX.Y.Z` with the tag from the output above):
 
```bash
git checkout vX.Y.Z
```
 
!!! tip "Why pin to a release tag?"
    The `main` branch reflects active development and may contain breaking changes.
    Pinning to a release tag ensures your results are reproducible and that you are
    running a version that has been tested end-to-end.
 
---
 
## 4. Verify the Installation
 
Run the bundled test dataset to confirm everything is working:
 
```bash
nextflow run -c nextflow.config main.nf -profile test,docker
```
 
Use `-profile test,singularity` if you installed Singularity instead of Docker.
 
On first run, Nextflow will pull the required container images from Docker Hub. This
requires outbound internet access and may take a few minutes depending on your connection.
On HPC systems with restricted network access, contact your sysadmin about using a local
container registry or pre-pulling images.
 
A successful run will produce output in `./results/` and print a completion summary to
the terminal.
