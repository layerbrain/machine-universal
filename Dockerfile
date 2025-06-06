FROM ubuntu:24.04

ENV LANG="C.UTF-8"
ENV HOME=/root

### BASE ###

RUN apt-get update \
    && apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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
        libpython3-dev \
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
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

### BASH ###

# Install latest bash and common shell tools
RUN apt-get update && apt-get install -y --no-install-recommends \
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
        emacs-nox \
    && rm -rf /var/lib/apt/lists/*

### PYTHON ###

ARG PYENV_VERSION=v2.5.5
ARG PYTHON_VERSION=3.13

# Install pyenv
ENV PYENV_ROOT=/root/.pyenv
ENV PATH=$PYENV_ROOT/bin:$PATH
RUN git -c advice.detachedHead=0 clone --branch ${PYENV_VERSION} --depth 1 https://github.com/pyenv/pyenv.git "${PYENV_ROOT}" \
    && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> /etc/profile \
    && echo 'export PATH="$$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"' >> /etc/profile \
    && echo 'eval "$(pyenv init - bash)"' >> /etc/profile \
    && cd ${PYENV_ROOT} && src/configure && make -C src

# Install Python versions with cache mount for downloads
RUN --mount=type=cache,target=/root/.pyenv/cache \
    pyenv install 3.10 3.11 3.12 3.13 \
    && pyenv global ${PYTHON_VERSION}

# Install pipx for common global package managers
ENV PIPX_BIN_DIR=/root/.local/bin
ENV PATH=$PIPX_BIN_DIR:$PATH
RUN apt-get update && apt-get install -y pipx \
    && rm -rf /var/lib/apt/lists/* \
    && pipx install poetry uv

# Preinstall common packages for each version with pip cache
RUN --mount=type=cache,target=/root/.cache/pip \
    for pyv in $(ls ${PYENV_ROOT}/versions/); do \
        ${PYENV_ROOT}/versions/$pyv/bin/pip install --upgrade pip ruff black mypy pyright isort; \
    done
# Reduce the verbosity of uv
ENV UV_NO_PROGRESS=1

### NODE ###

ARG NVM_VERSION=v0.40.2
ARG NODE_VERSION=22

ENV NVM_DIR=/root/.nvm
ENV COREPACK_DEFAULT_TO_LATEST=0
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV COREPACK_ENABLE_AUTO_PIN=0
ENV COREPACK_ENABLE_STRICT=0
RUN git -c advice.detachedHead=0 clone --branch ${NVM_VERSION} --depth 1 https://github.com/nvm-sh/nvm.git "${NVM_DIR}" \
    && echo 'source $NVM_DIR/nvm.sh' >> /etc/profile \
    && echo "prettier\neslint\ntypescript" > $NVM_DIR/default-packages \
    && . $NVM_DIR/nvm.sh \
    && nvm install 18 \
    && nvm install 20 \
    && nvm install 22 \
    && nvm alias default $NODE_VERSION \
    && corepack enable \
    && corepack install -g yarn pnpm npm

### BUN ###

ARG BUN_VERSION=latest

ENV BUN_INSTALL=/root/.bun
ENV PATH="$BUN_INSTALL/bin:$PATH"

RUN curl -fsSL https://bun.sh/install | bash \
    && echo 'export BUN_INSTALL=/root/.bun' >> /etc/profile \
    && echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> /etc/profile

### JAVA ###

ARG JAVA_VERSION=21
ARG GRADLE_VERSION=8.14
ARG MAVEN_VERSION=3.9.6

ENV GRADLE_HOME=/opt/gradle
ENV MAVEN_HOME=/opt/maven
ENV PATH=$GRADLE_HOME/bin:$MAVEN_HOME/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-${JAVA_VERSION}-jdk \
    && rm -rf /var/lib/apt/lists/* \
    # Install Gradle
    && curl -LO "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    && unzip gradle-${GRADLE_VERSION}-bin.zip \
    && rm gradle-${GRADLE_VERSION}-bin.zip \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    # Install Maven - using a more specific mirror URL
    && curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -o maven.tar.gz \
    && tar -xzf maven.tar.gz \
    && rm maven.tar.gz \
    && mv apache-maven-${MAVEN_VERSION} "${MAVEN_HOME}/"

### SWIFT ###

ARG SWIFT_VERSION=6.1

# Install swift
RUN mkdir /tmp/swiftly \
    && cd /tmp/swiftly \
    && curl -O https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz \
    && tar zxf swiftly-$(uname -m).tar.gz \
    && ./swiftly init --quiet-shell-followup -y \
    && echo '. ~/.local/share/swiftly/env.sh' >> /etc/profile \
    && bash -lc "swiftly install --use ${SWIFT_VERSION}" \
    && rm -rf /tmp/swiftly

ENV PATH=/root/.local/share/swiftly/toolchains/latest/usr/bin:$PATH

### RUBY ###

ARG RUBY_VERSION=3.3

ENV PATH=/root/.local/share/gem/ruby/3.3.0/bin:$PATH
RUN apt-get update && apt-get install -y --no-install-recommends \
        ruby-full \
        rbenv \
    && rm -rf /var/lib/apt/lists/* \
    && gem install bundler rails

### RUST ###

ARG RUST_VERSION=stable

ENV PATH=/root/.cargo/bin:$PATH
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
        sh -s -- -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && . "$HOME/.cargo/env" \
    && rustup component add rustfmt clippy \
    && cargo install sccache

### GO ###

ARG GO_VERSION=1.23.8

ENV PATH=/usr/local/go/bin:$HOME/go/bin:$PATH
RUN --mount=type=cache,target=/root/go/pkg \
    curl -L --fail https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz \
    && go install golang.org/x/tools/gopls@latest \
    && go install github.com/go-delve/delve/cmd/dlv@latest

### C/C++ ###

RUN apt-get update && apt-get install -y --no-install-recommends \
        clang \
        clang-format \
        clang-tidy \
        cmake \
        ccache \
        ninja-build \
        valgrind \
        gdb \
    && rm -rf /var/lib/apt/lists/*
    

### DOTNET ###

ARG DOTNET_VERSION=8.0

RUN curl -L https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh --channel ${DOTNET_VERSION} \
    && rm /tmp/dotnet-install.sh \
    && echo 'export DOTNET_ROOT=$HOME/.dotnet' >> /etc/profile \
    && echo 'export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools' >> /etc/profile

### PHP ###

RUN apt-get update && apt-get install -y --no-install-recommends \
        php \
        php-cli \
        php-curl \
        php-mbstring \
        php-xml \
        php-zip \
        composer \
    && rm -rf /var/lib/apt/lists/*

### BAZEL ###

RUN curl -L --fail https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 -o /usr/local/bin/bazelisk \
    && chmod +x /usr/local/bin/bazelisk \
    && ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

### DOCKER ###

RUN apt-get update && apt-get install -y --no-install-recommends \
        docker.io \
        docker-compose \
    && rm -rf /var/lib/apt/lists/*

### CLOUD TOOLS ###

# AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" \
    && unzip /tmp/awscliv2.zip -d /tmp/ \
    && /tmp/aws/install \
    && rm -rf /tmp/aws*

# Google Cloud SDK
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update && apt-get install -y google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

### DATABASE TOOLS ###

RUN apt-get update && apt-get install -y --no-install-recommends \
        postgresql-client \
        mysql-client \
        redis-tools \
        mongodb-clients \
    && rm -rf /var/lib/apt/lists/*

### SETUP SCRIPTS ###

COPY setup.sh /opt/layerbrain/setup.sh
RUN chmod +x /opt/layerbrain/setup.sh

COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

ENTRYPOINT ["/opt/start.sh"]