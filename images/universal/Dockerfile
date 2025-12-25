# syntax=docker/dockerfile:1.4
###############################################################################
#                                  BUILDER                                     #
###############################################################################
FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    HOME=/root \
    PATH=/usr/local/go/bin:/root/.cargo/bin:/root/.local/bin:$PATH

###############################################################################
# 1) APT + all base packages (no cache mount to avoid lock issues)
###############################################################################
RUN rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* /var/cache/apt/archives/lock && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        binutils \
        sudo \
        build-essential \
        bzr \
        curl \
        wget \
        default-libmysqlclient-dev \
        dnsutils \
        gettext \
        git \
        git-lfs \
        gnupg2 \
        inotify-tools \
        iputils-ping \
        jq \
        libbz2-dev \
        libc6 \
        libc6-dev \
        libcurl4-openssl-dev \
        libdb-dev \
        libedit2 \
        libffi-dev \
        libgcc-13-dev \
        libgcc1 \
        libgdbm-compat-dev \
        libgdbm-dev \
        libgdiplus \
        libgssapi-krb5-2 \
        liblzma-dev \
        libncurses-dev \
        libncursesw5-dev \
        libnss3-dev \
        libpq-dev \
        libpsl-dev \
        libpython3-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libstdc++-13-dev \
        libunwind8 \
        libuuid1 \
        libxml2-dev \
        libz3-dev \
        libicu-dev \
        libedit-dev \
        make \
        moreutils \
        netcat-openbsd \
        openssh-client \
        pkg-config \
        protobuf-compiler \
        python3-pip \
        ripgrep \
        rsync \
        software-properties-common \
        sqlite3 \
        swig3.0 \
        tk-dev \
        tzdata \
        unixodbc-dev \
        unzip \
        uuid-dev \
        xz-utils \
        zip \
        zlib1g \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# 2) Bash and shell tools
###############################################################################
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        bash-completion \
        zsh \
        fish \
        tmux \
        screen \
        htop \
        ncdu \
        tree \
        vim \
        nano \
        emacs-nox && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# 3) Python (pyenv + versions) + pipx + pip cache
###############################################################################
ARG PYENV_VERSION=v2.5.5
ARG PYTHON_VERSION=3.13
ENV PYENV_ROOT=/root/.pyenv
ENV PATH=$PYENV_ROOT/bin:$PATH

RUN git -c advice.detachedHead=0 clone --branch ${PYENV_VERSION} --depth 1 https://github.com/pyenv/pyenv.git "${PYENV_ROOT}" && \
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> /etc/profile && \
    echo 'export PATH="$$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"' >> /etc/profile && \
    echo 'eval "$(pyenv init - bash)"' >> /etc/profile && \
    cd ${PYENV_ROOT} && src/configure && make -C src

# Install Python versions separately for better caching
RUN --mount=type=cache,target=/root/.pyenv/cache \
    pyenv install 3.10

RUN --mount=type=cache,target=/root/.pyenv/cache \
    pyenv install 3.11

RUN --mount=type=cache,target=/root/.pyenv/cache \
    pyenv install 3.12

RUN --mount=type=cache,target=/root/.pyenv/cache \
    pyenv install 3.13 && pyenv global ${PYTHON_VERSION}

ENV PIPX_BIN_DIR=/root/.local/bin
ENV PATH=$PIPX_BIN_DIR:$PATH

RUN rm -f /var/lib/apt/lists/lock && \
    apt-get update && apt-get install -y pipx && rm -rf /var/lib/apt/lists/* && \
    pipx install poetry uv

RUN --mount=type=cache,target=/root/.cache/pip \
    for pyv in $(ls ${PYENV_ROOT}/versions/); do \
        ${PYENV_ROOT}/versions/$pyv/bin/pip install --upgrade pip ruff black mypy pyright isort; \
    done

ENV UV_NO_PROGRESS=1

###############################################################################
# 4) Node + Bun
###############################################################################
ARG NVM_VERSION=v0.40.2
ARG NODE_VERSION=22

ENV NVM_DIR=/root/.nvm
ENV COREPACK_DEFAULT_TO_LATEST=0
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV COREPACK_ENABLE_AUTO_PIN=0
ENV COREPACK_ENABLE_STRICT=0

RUN git -c advice.detachedHead=0 clone --branch ${NVM_VERSION} --depth 1 https://github.com/nvm-sh/nvm.git "${NVM_DIR}" && \
    echo 'source $NVM_DIR/nvm.sh' >> /etc/profile && \
    echo "prettier\neslint\ntypescript" > $NVM_DIR/default-packages && \
    . $NVM_DIR/nvm.sh && \
    nvm install 18 && \
    nvm install 20 && \
    nvm install 22 && \
    nvm alias default $NODE_VERSION && \
    corepack enable && \
    corepack install -g yarn pnpm npm

ARG BUN_VERSION=latest
ENV BUN_INSTALL=/root/.bun
ENV PATH="$BUN_INSTALL/bin:$PATH"

RUN curl -fsSL https://bun.sh/install | bash && \
    echo 'export BUN_INSTALL=/root/.bun' >> /etc/profile && \
    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> /etc/profile

###############################################################################
# 5) Java + Gradle + Maven
###############################################################################
ARG JAVA_VERSION=21
ARG GRADLE_VERSION=8.14
ARG MAVEN_VERSION=3.9.6

ENV GRADLE_HOME=/opt/gradle
ENV MAVEN_HOME=/opt/maven
ENV PATH=$GRADLE_HOME/bin:$MAVEN_HOME/bin:$PATH

RUN --mount=type=cache,target=/var/cache/apt \
    rm -f /var/lib/apt/lists/lock && \
    apt-get update && apt-get install -y --no-install-recommends openjdk-${JAVA_VERSION}-jdk && rm -rf /var/lib/apt/lists/*

RUN curl -LO "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" && \
    unzip gradle-${GRADLE_VERSION}-bin.zip && \
    rm gradle-${GRADLE_VERSION}-bin.zip && \
    mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/"

RUN curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -o maven.tar.gz && \
    tar -xzf maven.tar.gz && rm maven.tar.gz && mv apache-maven-${MAVEN_VERSION} "${MAVEN_HOME}/"

###############################################################################
# 6) Swift
###############################################################################
ARG SWIFT_VERSION=6.1

RUN mkdir /tmp/swiftly && cd /tmp/swiftly && \
    curl -O https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz && \
    tar zxf swiftly-$(uname -m).tar.gz && \
    ./swiftly init --quiet-shell-followup -y && \
    echo '. ~/.local/share/swiftly/env.sh' >> /etc/profile && \
    bash -lc "swiftly install --use ${SWIFT_VERSION}" && \
    rm -rf /tmp/swiftly

ENV PATH=/root/.local/share/swiftly/toolchains/latest/usr/bin:$PATH

###############################################################################
# 7) Ruby
###############################################################################
ARG RUBY_VERSION=3.3
ENV PATH=/root/.local/share/gem/ruby/3.3.0/bin:$PATH

RUN rm -f /var/lib/apt/lists/lock && \
    apt-get update && apt-get install -y --no-install-recommends ruby-full rbenv && rm -rf /var/lib/apt/lists/* && \
    gem install bundler rails

###############################################################################
# 8) Rust
###############################################################################
ARG RUST_VERSION=stable

RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
        sh -s -- -y --profile minimal --default-toolchain ${RUST_VERSION} && \
    . "$HOME/.cargo/env" && \
    rustup component add rustfmt clippy && \
    cargo install sccache

###############################################################################
# 9) Go per-arch
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
    tar -C /usr/local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz && \
    /usr/local/go/bin/go install golang.org/x/tools/gopls@latest && \
    /usr/local/go/bin/go install github.com/go-delve/delve/cmd/dlv@latest

###############################################################################
# 10) C/C++
###############################################################################
RUN --mount=type=cache,target=/var/cache/apt \
    rm -f /var/lib/apt/lists/lock && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        clang \
        clang-format \
        clang-tidy \
        cmake \
        ccache \
        ninja-build \
        valgrind \
        gdb && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# 11) .NET
###############################################################################
ARG DOTNET_VERSION=8.0

RUN curl -L https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel ${DOTNET_VERSION} && \
    rm /tmp/dotnet-install.sh && \
    echo 'export DOTNET_ROOT=$HOME/.dotnet' >> /etc/profile && \
    echo 'export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools' >> /etc/profile

###############################################################################
# 12) PHP
###############################################################################
RUN --mount=type=cache,target=/var/cache/apt \
    rm -f /var/lib/apt/lists/lock && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        php \
        php-cli \
        php-curl \
        php-mbstring \
        php-xml \
        php-zip \
        composer && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# 13) Bazel
###############################################################################
RUN curl -L --fail https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 -o /usr/local/bin/bazelisk && \
    chmod +x /usr/local/bin/bazelisk && \
    ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

###############################################################################
# 14) Docker CLI
###############################################################################
RUN --mount=type=cache,target=/var/cache/apt \
    rm -f /var/lib/apt/lists/lock && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker.io docker-compose && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# 15) Cloud Tools
###############################################################################
# AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip /tmp/awscliv2.zip -d /tmp/&& \
    /tmp/aws/install && \
    rm -rf /tmp/aws*

# Google Cloud SDK
RUN rm -f /var/lib/apt/lists/lock && \
    apt-get update && \
    apt-get install -y apt-transport-https ca-certificates gnupg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update && \
    apt-get install -y google-cloud-cli && \
    rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

###############################################################################
# 16) Database Tools
###############################################################################
RUN rm -f /var/lib/apt/lists/lock && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        postgresql-client \
        mysql-client \
        redis-tools && \
    rm -rf /var/lib/apt/lists/*

# MongoDB Shell
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
        gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    rm -f /var/lib/apt/lists/lock && \
    apt-get update && \
    apt-get install -y --no-install-recommends mongodb-mongosh && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# 17) Python Async Libraries
###############################################################################
RUN --mount=type=cache,target=/root/.cache/pip \
    for pyv in $(ls ${PYENV_ROOT}/versions/); do \
        ${PYENV_ROOT}/versions/$pyv/bin/pip install \
            asyncpg \
            aiosqlite \
            aiohttp \
            asyncssh \
            httpx \
            uvloop \
            uvicorn; \
    done

###############################################################################
# 18) NeutronAPI (installed last for cache reuse; no pinning)
###############################################################################
ARG NEUTRONAPI_REFRESH=0
RUN --mount=type=cache,target=/root/.cache/pip \
    bash -lc "echo NEUTRONAPI_REFRESH=${NEUTRONAPI_REFRESH} >/dev/null && \
    for pyv in \$(ls ${PYENV_ROOT}/versions/); do \
        ${PYENV_ROOT}/versions/\$pyv/bin/python -m pip install --no-cache-dir --break-system-packages --upgrade neutronapi; \
    done"

###############################################################################
# Copy setup and start scripts
###############################################################################
COPY ../../setup.sh /opt/layerbrain/setup.sh
RUN chmod +x /opt/layerbrain/setup.sh
COPY ../../start.sh /opt/start.sh
RUN chmod +x /opt/start.sh
COPY ../../init-env.sh /opt/layerbrain/init-env.sh
RUN chmod +x /opt/layerbrain/init-env.sh

###############################################################################
#                                RUNTIME                                     #
###############################################################################
FROM ubuntu:24.04 AS runtime
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    HOME=/root \
    PATH=/usr/local/go/bin:/root/.cargo/bin:/root/.local/bin:/root/.pyenv/shims:/root/.pyenv/bin:/root/.nvm/versions/node/v22.0.0/bin:/root/.bun/bin:$PATH

# Install all development tools and runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        binutils \
        sudo \
        build-essential \
        bzr \
        ca-certificates \
        curl \
        wget \
        default-libmysqlclient-dev \
        dnsutils \
        gettext \
        git \
        git-lfs \
        gnupg2 \
        inotify-tools \
        iputils-ping \
        jq \
        libbz2-dev \
        libbz2-1.0 \
        libc6 \
        libc6-dev \
        libcurl4-openssl-dev \
        libdb-dev \
        libedit2 \
        libffi-dev \
        libffi8 \
        libgcc-13-dev \
        libgcc1 \
        libgcc-s1 \
        libgdbm-compat-dev \
        libgdbm-dev \
        libgdiplus \
        libgssapi-krb5-2 \
        libicu74 \
        liblzma-dev \
        liblzma5 \
        libncurses-dev \
        libncurses6 \
        libncursesw5-dev \
        libnss3-dev \
        libpq-dev \
        libpq5 \
        libpsl-dev \
        libpython3-dev \
        libreadline-dev \
        libreadline8 \
        libsqlite3-dev \
        libsqlite3-0 \
        libssl-dev \
        libssl3 \
        libstdc++-13-dev \
        libstdc++6 \
        libunwind8 \
        libuuid1 \
        libxml2 \
        libxml2-dev \
        libxslt1.1 \
        libz3-dev \
        libicu-dev \
        libedit-dev \
        libmysqlclient21 \
        make \
        moreutils \
        netcat-openbsd \
        openssh-client \
        openssh-server \
        pkg-config \
        protobuf-compiler \
        python3-pip \
        ripgrep \
        rsync \
        software-properties-common \
        sqlite3 \
        swig3.0 \
        tk-dev \
        tzdata \
        unixodbc-dev \
        unzip \
        uuid-dev \
        xz-utils \
        zip \
        zlib1g \
        zlib1g-dev \
        bash \
        bash-completion \
        zsh \
        fish \
        tmux \
        screen \
        htop \
        lsof \
        procps \
        ncdu \
        tree \
        vim \
        nano \
        emacs-nox \
        pipx \
        openjdk-21-jdk \
        ruby-full \
        rbenv \
        clang \
        clang-format \
        clang-tidy \
        cmake \
        ccache \
        ninja-build \
        valgrind \
        gdb \
        php \
        php-cli \
        php-curl \
        php-mbstring \
        php-xml \
        php-zip \
        composer \
        docker.io \
        docker-compose \
        iptables \
        postgresql-client \
        mysql-client \
        redis-tools \
        apt-transport-https && \
    rm -rf /var/lib/apt/lists/*

# Copy language runtimes and tools
COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /root/.cargo /root/.cargo
COPY --from=builder /root/.pyenv /root/.pyenv
COPY --from=builder /root/.nvm /root/.nvm
COPY --from=builder /root/.bun /root/.bun
COPY --from=builder /root/.local /root/.local
COPY --from=builder /opt/gradle /opt/gradle
COPY --from=builder /opt/maven /opt/maven
COPY --from=builder /root/.dotnet /root/.dotnet
COPY --from=builder /usr/local/bin/bazel* /usr/local/bin/
COPY --from=builder /etc/profile /etc/profile

# Copy scripts
COPY --from=builder /opt/layerbrain/setup.sh /opt/layerbrain/setup.sh
COPY --from=builder /opt/start.sh /opt/start.sh
COPY --from=builder /opt/layerbrain/init-env.sh /opt/layerbrain/init-env.sh

# Configure Docker for nested containers
RUN mkdir -p /etc/docker && \
    echo '{"mtu": 1450, "ipv6": false}' > /etc/docker/daemon.json

# Enable IP forwarding for nested containers
RUN echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf && \
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Configure SSH and environment
RUN mkdir -p /var/run/sshd /root/.ssh /etc/profile.d && \
    chmod 700 /root/.ssh && \
    echo 'source /opt/layerbrain/init-env.sh' >> /root/.bashrc && \
    cp /opt/layerbrain/init-env.sh /etc/profile.d/layerbrain.sh && \
    echo 'PermitUserEnvironment yes' >> /etc/ssh/sshd_config && \
    echo 'PATH=/usr/local/go/bin:/root/.cargo/bin:/root/.local/bin:/root/.pyenv/shims:/root/.pyenv/bin:/root/.nvm/versions/node/v22.0.0/bin:/root/.bun/bin:/opt/gradle/bin:/opt/maven/bin:/root/.dotnet:/root/.dotnet/tools:/root/.local/share/swiftly/toolchains/latest/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' > /root/.ssh/environment && \
    chmod 600 /root/.ssh/environment

EXPOSE 22

ENTRYPOINT ["/opt/start.sh"]
