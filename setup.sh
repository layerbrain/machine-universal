#!/bin/bash

echo "=================================="
echo "Setting up Layerbrain environment..."
echo "=================================="

# Create standard user directories (macOS-like) in ~/brain
# Uses ~/brain for OS-agnostic paths (works on Linux and macOS)
BRAIN_HOME=~/brain
mkdir -p "$BRAIN_HOME/Desktop"
mkdir -p "$BRAIN_HOME/Documents"
mkdir -p "$BRAIN_HOME/Downloads"
mkdir -p "$BRAIN_HOME/Music"
mkdir -p "$BRAIN_HOME/Pictures"
mkdir -p "$BRAIN_HOME/Movies"
mkdir -p "$BRAIN_HOME/Uploads"
mkdir -p "$BRAIN_HOME/applications"

# Configure Python version if specified
if [ ! -z "$LAYERBRAIN_ENV_PYTHON_VERSION" ]; then
    echo "Setting Python version to $LAYERBRAIN_ENV_PYTHON_VERSION"
    pyenv global $LAYERBRAIN_ENV_PYTHON_VERSION
fi

# Configure Node version if specified
if [ ! -z "$LAYERBRAIN_ENV_NODE_VERSION" ]; then
    echo "Setting Node version to $LAYERBRAIN_ENV_NODE_VERSION"
    source $NVM_DIR/nvm.sh
    nvm use $LAYERBRAIN_ENV_NODE_VERSION
fi

# Configure Rust version if specified
if [ ! -z "$LAYERBRAIN_ENV_RUST_VERSION" ]; then
    echo "Setting Rust version to $LAYERBRAIN_ENV_RUST_VERSION"
    rustup default $LAYERBRAIN_ENV_RUST_VERSION
fi

# Configure Go version if specified
if [ ! -z "$LAYERBRAIN_ENV_GO_VERSION" ]; then
    echo "Installing Go version $LAYERBRAIN_ENV_GO_VERSION"
    curl -L --fail https://go.dev/dl/go${LAYERBRAIN_ENV_GO_VERSION}.linux-amd64.tar.gz -o /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
fi

# Configure Swift version if specified
if [ ! -z "$LAYERBRAIN_ENV_SWIFT_VERSION" ]; then
    echo "Setting Swift version to $LAYERBRAIN_ENV_SWIFT_VERSION"
    bash -lc "swiftly use $LAYERBRAIN_ENV_SWIFT_VERSION"
fi

# Configure Java version if specified
if [ ! -z "$LAYERBRAIN_ENV_JAVA_VERSION" ]; then
    echo "Setting Java version to $LAYERBRAIN_ENV_JAVA_VERSION"
    update-alternatives --set java /usr/lib/jvm/java-${LAYERBRAIN_ENV_JAVA_VERSION}-openjdk-amd64/bin/java
fi

# Configure Ruby version if specified
if [ ! -z "$LAYERBRAIN_ENV_RUBY_VERSION" ]; then
    echo "Ruby version configuration: $LAYERBRAIN_ENV_RUBY_VERSION"
    # Ruby version management would go here if using rbenv/rvm
fi

# Display installed versions
echo ""
echo "=== Installed Language Versions ==="
echo "Python: $(python --version 2>&1)"
echo "Node: $(node --version 2>&1)"
echo "Rust: $(rustc --version 2>&1)"
echo "Go: $(go version 2>&1)"
echo "Swift: $(swift --version 2>&1 | head -n 1)"
echo "Java: $(java --version 2>&1 | head -n 1)"
echo "Ruby: $(ruby --version 2>&1)"
echo "PHP: $(php --version 2>&1 | head -n 1)"
echo "Dotnet: $(dotnet --version 2>&1)"
echo "=================================="

# Start Docker daemon if not already running
echo ""
echo "=== Starting Docker ==="
if docker info >/dev/null 2>&1; then
    echo "Docker is already running."
else
    echo "Starting Docker daemon..."

    # Apply sysctl settings for nested containers
    sysctl -p /etc/sysctl.conf >/dev/null 2>&1 || true

    # Clean up stale state files
    rm -f /var/run/docker.pid /var/run/docker.sock

    # Create necessary directories
    mkdir -p /var/lib/docker /var/log

    # Start Docker daemon (config from /etc/docker/daemon.json)
    dockerd > /var/log/dockerd.log 2>&1 &

    # Wait for Docker to be ready
    echo -n "Waiting for Docker to be ready"
    DOCKER_READY=0
    for i in {1..30}; do
        if docker info >/dev/null 2>&1; then
            DOCKER_READY=1
            echo ""
            echo "Docker started successfully."
            break
        fi
        echo -n "."
        sleep 1
    done

    if [ $DOCKER_READY -eq 0 ]; then
        echo ""
        echo "Warning: Docker failed to start within 30 seconds."
        echo "Check /var/log/dockerd.log for details."
    fi
fi
echo "=================================="
