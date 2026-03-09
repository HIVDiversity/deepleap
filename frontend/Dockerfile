# An example of using standalone Python builds with multistage images.

# First, build the application in the `/app` directory
FROM ghcr.io/astral-sh/uv:bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# Omit development dependencies
ENV UV_NO_DEV=1

# Configure the Python directory so it is consistent
ENV UV_PYTHON_INSTALL_DIR=/python

# Only use the managed Python version
ENV UV_PYTHON_PREFERENCE=only-managed

# Install Python before the project for caching
RUN uv python install 3.12

WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project


COPY pyproject.toml uv.lock* README.md ./
COPY frontend/ ./frontend/

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Then, use a final image without uv
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    openssh-client \
    git \
    wget


# pre-add a "docker" group for socket usage
RUN set -eux; groupadd -g 2375 --system docker &&\
    wget -O 'docker.tgz' 'https://download.docker.com/linux/static/stable/x86_64/docker-29.2.1.tgz' && \
    tar --extract \
    --file docker.tgz \
    --strip-components 1 \
    --directory /usr/local/bin/ \
    --no-same-owner \
    'docker/docker'  && \
    rm docker.tgz && \
    docker --version


RUN groupadd -g 855 -r deepleap && useradd -r -u 855 --create-home -g deepleap deepleap && usermod -aG docker deepleap

# Copy the Python version
COPY --from=builder --chown=python:python /python /python

# Copy the application from the builder
COPY --from=builder --chown=deepleap:deepleap /app /app


# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"


# RUN uv pip install . && chown -R deepleap:deepleap /app
# Reset the entrypoint, don't invoke `uv`
ENTRYPOINT []

RUN mkdir /data && chown deepleap:deepleap /data

USER deepleap

WORKDIR /app

CMD ["python", "frontend/main.py", "run"]
