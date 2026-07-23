---
icon: lucide/container
---

# Containerization
DeepLEAP can be run from within a container. This, however, necessitates some docker hackery, since we must enable the container to be called from another container.


There are two primary docker images here: first, the frontend image `deepleap-frontend` and second the pipeline itself, `deepleap`.

## Pipeline Image

The `deepleap` image is built from the `Dockerfile` at the root of this repo. It
bundles everything needed to launch a run without installing anything locally:

- Nextflow
- A JDK
- The Docker CLI
- A non-root user, `deepleap` (uid `855`), that the container runs as

It does **not** bundle the per-module tools (MAFFT, minimap2, and so on) — those are
pulled by Nextflow itself as separate containers, one per process, when the pipeline
runs with `-profile docker` (see [Installation](../user-guide/installation.md)).

**Why Docker-in-Docker?** Nextflow, running inside the `deepleap` container, needs to
launch further sibling containers for each pipeline process on the host. It does this
by mounting the host's `/var/run/docker.sock` into the container, rather than by
running a nested Docker daemon. One consequence follows from this: any volume
Nextflow needs to read or write (input data, the work directory, `/tmp`) must be
mounted at the *same path* in both the `deepleap` container and the sibling
containers it launches, since paths passed to the sibling containers are resolved
against the host, not against the `deepleap` container's filesystem.

A minimal invocation, run directly without the frontend, looks like:

```bash
docker run \
  -v $PROCESSING_ROOT:$PROCESSING_ROOT \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp:/tmp \
  --group-add $DOCKER_GROUP_ID \
  dlejeune/deepleap \
  nextflow run -c nextflow.config main.nf ...
```

- `$PROCESSING_ROOT` — your input/output data directory, mounted at the same path
  inside and outside the container (see above).
- `/var/run/docker.sock` — gives the container's Nextflow process the ability to
  launch sibling containers on the host.
- `$DOCKER_GROUP_ID` — the group ID of the `docker` group on the host
  (`getent group docker | cut -d: -f3`); the container user needs to belong to it to
  use the mounted `docker.sock`.

This is the same mechanism the frontend uses internally — see `nextflow_binary` in
its configuration below.

## Frontend Setup
It's recommended to run the frontend through `docker-compose`, with an example setup shown here:

```yaml
services:
  deepleap-frontend:
    image: docker.io/dlejeune/deepleap-frontend
    container_name: deepleap-frontend
    restart: unless-stopped
    user: "855:855"
    group_add:
      - "$DOCKER_GROUP_ID"
    environment:
      DEEPLEAP_FRONTEND_CONFIG: /config/config.toml
    ports:
      - 8080:8080
    volumes:
      - $PROCESSING_ROOT:$PROCESSING_ROOT
      - /var/run/docker.sock:/var/run/docker.sock
      - ./config_v2.toml:/config/config.toml:ro
```
Some of the variables to note:
- `user 855`: The container image expects to run as the non-root user `855`. You will need to ensure that there is a user with this ID on your system that has write access to the relevant volumes you mount into this container. If you wish to change the user ID, you must modify the Dockerfile for the frontend image and rebuild it.
- `DOCKER_GROUP_ID`: the group ID of the docker group on your system (`getent group docker | cut -d: -f3`). This is necessary to allow the frontend container to call docker commands on the host system.
- `PROCESSING_ROOT`: the directory on the host system where you want to store your input and output data. This is mounted as a volume in the container, so that the pipeline can read and write data to it. This should be an absolute path, e.g. `/home/user/data`, and should be writable by the container user.
- `./config_v2.toml`: the configuration file for the frontend. An example config file is provided below.

### Configuration
The configuration file for the frontend is a TOML file with the following structure:

```toml
nextflow_binary = "docker run -v /home/deepleap/processing_root:/home/deepleap/processing_root --group-add 960 -v /var/run/docker.sock:/var/run/docker.sock -v /tmp:/tmp dlejeune/deepleap nextflow"

nextflow_config_file="/deepleap/nextflow.config"
nextflow_work_dir="/home/deepleap/processing_root/nf_work"
nextflow_cache_dir="/home/deepleap/processing_root/nf_cache"

nextflow_main_script="/deepleap/main.nf"
nextflow_log_path = "/home/deepleap/processing_root/nf_logs/nextflow.log"

data_dir = "/home/deepleap/processing_root/run_data/"

max_memory = "16.GB"
max_cpus = "16"
max_time = "24.h"

db_url="sqlite:////home/deepleap/processing_root/deepleap_runs.db"

port=5050
```
A few notes on the configuration:

- **`nextflow_binary`** — the command used to invoke Nextflow, running it from
  within the `deepleap` container with the volumes and group permissions it needs to
  read/write data and call Docker on the host. Adjust the volume mounts and
  `--group-add` value to match your system.

    !!! warning
        A mount for `/tmp` is required. Without it, Nextflow cannot create
        temporary files and the run will fail.

- **`nextflow_config_file`** — path to `nextflow.config` inside the `deepleap`
  image; leave this pointing at the container's own copy.
- **`nextflow_work_dir`**, **`nextflow_cache_dir`**, **`nextflow_log_path`** — the
  Nextflow work directory, cache directory, and log file. All three should live
  under `PROCESSING_ROOT`, so they're writable by the container user and persist
  across container restarts.
- **`data_dir`** — where the frontend stores run data. Also under `PROCESSING_ROOT`.
- **`db_url`** — the frontend's run-tracking database. Also under `PROCESSING_ROOT`;
  you shouldn't need to change this.
- **`port`** — the port the frontend listens on. Change if it conflicts with
  something else on your host.
- **`max_memory`**, **`max_cpus`**, **`max_time`** — resource caps the frontend
  applies to pipeline runs. Match these to what's actually available on your system.
