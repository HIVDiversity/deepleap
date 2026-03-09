# Containerization
DeepLEAP can be run from within a container. This, however, necessitates some docker hackery, since we must enable the container to be called from another container.


There are two primary docker images here: first, the frontend image `deepleap-frontend` and second the pipeline itself, `deepleap`.

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
- `DOCKER_GROUP_ID`: the group ID of the docker group on your system. This is necessary to allow the frontend container to call docker commands on the host system.
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
- `nextflow_binary`: the command to run nextflow. This is set to run nextflow from within the `deepleap` container, with the necessary volumes and group permissions to allow it to read and write data and call docker commands on the host system. You may need to modify the volume mounts and group permissions to match your system setup. Note that it is imperative to mount a path to the `/tmp` directory in the nextflow container, since otherwise nextflow will not be able to create temporary files and will fail.
- `nextflow_config_file`: the path to the nextflow configuration file within the container. This should point to the `nextflow.config` file in the `deepleap` image.
- `nextflow_work_dir`, `nextflow_cache_dir`, `nextflow_log_path`: paths to the nextflow work directory, cache directory, and log file. These should be within the `PROCESSING_ROOT` directory that you mount into the container, so that they are writable by the container user and persist across container restarts.
- `data_dir`: the directory where the frontend will store run data. This should also be within the `PROCESSING_ROOT` directory.
- `db_url`: the URL for the database where the frontend will store run information. This should also be within the `PROCESSING_ROOT` directory. You shouldn't need to modify this.
- `port`: the port on which the frontend will run. You can modify this if you want to run the frontend on a different port.
- `max_memory`, `max_cpus`, `max_time`: the maximum memory, CPU, and time resources that the frontend will allow for pipeline runs. You can modify these to match the resources available on your system.
