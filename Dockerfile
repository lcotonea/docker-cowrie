# This Dockerfile contains two images, `builder` and `runtime`.
# `builder` contains all necessary code to build
# `runtime` is stripped down.

FROM debian:buster-slim as builder
LABEL maintainer="Michel Oosterhof <michel@oosterhof.net>"

ENV COWRIE_GROUP=cowrie \
    COWRIE_USER=cowrie \
    COWRIE_HOME=/cowrie

# Set locale to UTF-8, otherwise upstream libraries have bytes/string conversion issues
ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

RUN groupadd -r -g 1000 ${COWRIE_GROUP} && \
    useradd -r -u 1000 -d ${COWRIE_HOME} -m -g ${COWRIE_GROUP} ${COWRIE_USER}

# Set up Debian prereqs
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y \
        -o APT::Install-Suggests=false \
        -o APT::Install-Recommends=false \
      python3-pip \
      libssl-dev \
      libffi-dev \
      python3-dev \
      python3-venv \
      python3 \
      gcc \
      git \
      build-essential \
      python3-virtualenv \
      libsnappy-dev \
      default-libmysqlclient-dev && \
    rm -rf /var/lib/apt/lists/*

# Build a cowrie environment from github master HEAD.

USER ${COWRIE_USER}

RUN git clone --separate-git-dir=/tmp/cowrie.git https://github.com/cowrie/cowrie ${COWRIE_HOME}/cowrie-git && \
    cd ${COWRIE_HOME} && \
      python3 -m venv cowrie-env && \
      . cowrie-env/bin/activate && \
      pip install --no-cache-dir --upgrade pip && \
      pip install --no-cache-dir --upgrade cffi && \
      pip install --no-cache-dir --upgrade setuptools && \
      pip install --no-cache-dir --upgrade -r ${COWRIE_HOME}/cowrie-git/requirements.txt && \
      pip install --no-cache-dir --upgrade -r ${COWRIE_HOME}/cowrie-git/requirements-output.txt

FROM debian:buster-slim AS runtime
LABEL maintainer="Michel Oosterhof <michel@oosterhof.net>"

ENV COWRIE_GROUP=cowrie \
    COWRIE_USER=cowrie \
    COWRIE_HOME=/cowrie

RUN groupadd -r -g 1000 ${COWRIE_GROUP} && \
    useradd -r -u 1000 -d ${COWRIE_HOME} -m -g ${COWRIE_GROUP} ${COWRIE_USER}

RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y \
        -o APT::Install-Suggests=false \
        -o APT::Install-Recommends=false \
      libssl1.1 \
      libffi6 \
      procps \
      python3 && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/local/bin/python

COPY --from=builder ${COWRIE_HOME} ${COWRIE_HOME}
RUN chown -R ${COWRIE_USER}:${COWRIE_GROUP} ${COWRIE_HOME}

ENV PATH=${COWRIE_HOME}/cowrie-git/bin:${PATH}
ENV STDOUT=yes

USER ${COWRIE_USER}
WORKDIR ${COWRIE_HOME}/cowrie-git
ADD --chown=cowrie:cowrie entrypoint.sh /cowrie/entrypoint.sh

# preserve .dist file when etc/ volume is mounted, even if the etc volume is mount in read only mode and/or a secret mount volume
VOLUME [ "/cowrie/cowrie-git/var", "/cowrie/cowrie-git/etc-import" ]

ENTRYPOINT [ "/cowrie/entrypoint.sh" ]
CMD [ "start", "-n" ]
EXPOSE 2222 2223
