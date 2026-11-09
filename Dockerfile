# Hardware-free environment: both Python environments of the paper, make and git.
#   docker build -t sv30q .  &&  docker run --rm sv30q make test reproduce
FROM mambaorg/micromamba:2.0.5
USER root
RUN apt-get update && apt-get install -y --no-install-recommends make git && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /opt/envs && chown $MAMBA_USER:$MAMBA_USER /opt/envs
USER $MAMBA_USER
COPY --chown=$MAMBA_USER:$MAMBA_USER setup/env_fpga.yml setup/env_cpu.yml /tmp/setup/
RUN micromamba create -y -p /opt/envs/fpga -f /tmp/setup/env_fpga.yml \
 && micromamba create -y -p /opt/envs/cpu -f /tmp/setup/env_cpu.yml \
 && micromamba clean -a -y
ENV PY_FPGA=/opt/envs/fpga/bin/python PY_CPU=/opt/envs/cpu/bin/python
WORKDIR /work
COPY --chown=$MAMBA_USER:$MAMBA_USER . /work
RUN git config --global --add safe.directory /work
CMD ["make", "test", "reproduce"]
