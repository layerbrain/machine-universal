# syntax=docker/dockerfile:1.4
###############################################################################
#                            MINIMAL BUILDER                                 #
###############################################################################
FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    HOME=/root \
    PATH=/usr/local/go/bin:/root/.cargo/bin:/root/.local/bin:$PATH

###############################################################################
# Base packages and build tools
###############################################################################
RUN rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* /var/cache/apt/archives/lock && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        wget \
        git \
        pkg-config \
        libssl-dev \
        libffi-dev \
        zlib1g-dev \
        libreadline-dev \
        libsqlite3-dev \
        libbz2-dev \
        libncurses-dev \
        xz-utils \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# Python (single version)
###############################################################################
ARG PYTHON_VERSION=3.13
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-dev && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# Node.js (single version)
###############################################################################
ARG NODE_VERSION=22
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn pnpm && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# Rust
###############################################################################
ARG RUST_VERSION=stable
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
        sh -s -- -y --profile minimal --default-toolchain ${RUST_VERSION} && \
    . "$HOME/.cargo/env" && \
    rustup component add rustfmt clippy

###############################################################################
# Go
###############################################################################
ARG GO_VERSION=1.23.8
ARG TARGETPLATFORM
RUN --mount=type=cache,target=/root/go/pkg \
    set -eux; \
    case "${TARGETPLATFORM}" in \
      "linux/amd64") GOARCH=amd64;; \
      "linux/arm64") GOARCH=arm64;; \
      *) echo "Unsupported: ${TARGETPLATFORM}" >&2; exit 1;; \
    esac && \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz" -o /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz

###############################################################################
# C/C++ Standard Tools
###############################################################################
RUN --mount=type=cache,target=/var/cache/apt \
    rm -f /var/lib/apt/lists/lock && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        clang \
        make \
        cmake \
        ninja-build && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# Copy setup scripts
###############################################################################
COPY ../../setup.sh /opt/layerbrain/setup.sh
RUN chmod +x /opt/layerbrain/setup.sh
COPY ../../start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

###############################################################################
# NeutronAPI (install late for cache reuse; no pinning)
###############################################################################
ARG NEUTRONAPI_REFRESH=0
RUN --mount=type=cache,target=/root/.cache/pip \
    bash -lc "echo NEUTRONAPI_REFRESH=${NEUTRONAPI_REFRESH} >/dev/null && \
    pip3 install --no-cache-dir --upgrade neutronapi"

###############################################################################
#                            MINIMAL RUNTIME                                 #
###############################################################################
FROM ubuntu:24.04 AS runtime
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    HOME=/root \
    PATH=/usr/local/go/bin:/root/.cargo/bin:/root/.local/bin:$PATH

# Install minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        libssl3 \
        libc6 \
        libgcc-s1 \
        libstdc++6 \
        libncurses6 \
        libreadline8 \
        libsqlite3-0 \
        libffi8 \
        libbz2-1.0 \
        zlib1g && \
    rm -rf /var/lib/apt/lists/*

# Copy language runtimes
COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /root/.cargo /root/.cargo
COPY --from=builder /usr/bin/python3* /usr/bin/
COPY --from=builder /usr/lib/python3* /usr/lib/
COPY --from=builder /usr/local/lib/python3* /usr/local/lib/
COPY --from=builder /usr/bin/node /usr/bin/
COPY --from=builder /usr/bin/npm /usr/bin/
COPY --from=builder /usr/bin/npx /usr/bin/
COPY --from=builder /usr/bin/yarn /usr/bin/
COPY --from=builder /usr/bin/pnpm /usr/bin/
COPY --from=builder /usr/lib/node_modules /usr/lib/node_modules

# Copy scripts
COPY --from=builder /opt/layerbrain/setup.sh /opt/layerbrain/setup.sh
COPY --from=builder /opt/start.sh /opt/start.sh

ENTRYPOINT ["/opt/start.sh"]
