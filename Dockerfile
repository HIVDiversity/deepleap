FROM debian:bookworm-slim

RUN groupadd -g 855 -r deepleap && \
    useradd -r -u 855 --create-home -g deepleap deepleap && \
    groupadd -g 2375 --system docker



RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    openssh-client \
    git \
    procps \
    wget \
    java-common
RUN wget -O 'docker.tgz' 'https://download.docker.com/linux/static/stable/x86_64/docker-29.2.1.tgz' && \
    wget -O amazon-corretto-25-x64-linux-jdk.deb https://corretto.aws/downloads/latest/amazon-corretto-25-x64-linux-jdk.deb && \
    wget -O nextflow https://github.com/nextflow-io/nextflow/releases/download/v25.10.4/nextflow-25.10.4-dist


RUN tar --extract \
    --file docker.tgz \
    --strip-components 1 \
    --directory /usr/local/bin/ \
    --no-same-owner \
    'docker/docker'  && \
    rm docker.tgz

RUN dpkg -i amazon-corretto-25-x64-linux-jdk.deb && \
    rm amazon-corretto-25-x64-linux-jdk.deb

RUN chmod +x nextflow && \
    mv nextflow /usr/local/bin/ && \
    mkdir /data &&  \
    chown deepleap:deepleap /data
    # wget -O - --quiet https://get.nextflow.io | bash
# mv nextflow /usr/local/bin/ && \
# chmod +x /usr/local/bin/nextflow

USER deepleap

WORKDIR /deepleap
COPY . /deepleap
