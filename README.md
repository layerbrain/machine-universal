# Universal Machine

A comprehensive, zero-configuration development environment container that provides both universal and minimal Docker images for different use cases.

This repository offers two variants:
- **Universal**: Full-featured image with all major programming languages and development tools
- **Minimal**: Lightweight image with core languages only (Node.js, Python, Rust, Go, C++)

## Features

- **Multi-language support**: Python, Node.js, Go, Rust, Java, Ruby, Swift, PHP, .NET, and more
- **Pre-configured tools**: Package managers, linters, formatters, and build tools for each language
- **Cloud-ready**: AWS CLI, Google Cloud SDK, and Azure CLI pre-installed
- **Database clients**: PostgreSQL, MySQL, Redis, and MongoDB clients included
- **Zero setup**: Works out of the box with sensible defaults
- **Async API ready**: Includes Uvicorn and NeutronAPI for high-performance Python APIs

## Available Images

### Universal Image
Full-featured development environment with all languages and tools:

```bash
# AMD64
docker pull ghcr.io/layerbrain/machine-universal:universal-amd64-latest

# ARM64  
docker pull ghcr.io/layerbrain/machine-universal:universal-arm64-latest
```

### Minimal Image
Lightweight environment with core languages only:

```bash
# AMD64
docker pull ghcr.io/layerbrain/machine-universal:minimal-amd64-latest

# ARM64
docker pull ghcr.io/layerbrain/machine-universal:minimal-arm64-latest
```

## Quick Start

Run with your project mounted:

```bash
# Using universal image
docker run --rm -it \
    -v $(pwd):/workspace/$(basename $(pwd)) \
    -w /workspace/$(basename $(pwd)) \
    ghcr.io/layerbrain/machine-universal:universal-amd64-latest

# Using minimal image
docker run --rm -it \
    -v $(pwd):/workspace/$(basename $(pwd)) \
    -w /workspace/$(basename $(pwd)) \
    ghcr.io/layerbrain/machine-universal:minimal-amd64-latest
```

## SSH Access

The universal machine supports SSH access for remote development using SSH key authentication only.

### Using SSH Key Authentication

```bash
# Start container with your public key
docker run -d \
    -p 2222:22 \
    -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
    ghcr.io/layerbrain/machine-universal:universal-amd64-latest

# Connect via SSH with your private key
ssh -p 2222 -i ~/.ssh/id_rsa root@localhost
```

### Production Deployment

For cloud deployments (DigitalOcean, AWS, etc.), expose port 22 and use your server's public IP:

```bash
# On your server
docker run -d \
    -p 22:22 \
    -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
    -v /workspace:/workspace \
    ghcr.io/layerbrain/machine-universal:universal-amd64-latest

# From your local machine
ssh root@your-server-ip
```

## Customizing Runtime Versions

The machine-universal supports dynamic configuration of language runtimes through environment variables. Set any of the following `LAYERBRAIN_ENV_*` variables to customize your environment:

| Environment Variable | Description | Available Versions | Default |
|---------------------|-------------|-------------------|---------|
| `LAYERBRAIN_ENV_PYTHON_VERSION` | Python version | 3.10, 3.11, 3.12, 3.13 | 3.13 |
| `LAYERBRAIN_ENV_NODE_VERSION` | Node.js version | 18, 20, 22 | 22 |
| `LAYERBRAIN_ENV_RUST_VERSION` | Rust toolchain | stable, beta, nightly | stable |
| `LAYERBRAIN_ENV_GO_VERSION` | Go version | 1.23.x | 1.23.8 |
| `LAYERBRAIN_ENV_SWIFT_VERSION` | Swift version | 6.0, 6.1 | 6.1 |
| `LAYERBRAIN_ENV_JAVA_VERSION` | Java version | 21 | 21 |
| `LAYERBRAIN_ENV_RUBY_VERSION` | Ruby version | 3.3 | 3.3 |

### Example with custom versions:

```bash
docker run --rm -it \
    -e LAYERBRAIN_ENV_PYTHON_VERSION=3.11 \
    -e LAYERBRAIN_ENV_NODE_VERSION=20 \
    -e LAYERBRAIN_ENV_RUST_VERSION=nightly \
    -v $(pwd):/workspace/$(basename $(pwd)) \
    -w /workspace/$(basename $(pwd)) \
    ghcr.io/layerbrain/machine-universal:universal-amd64-latest
```

## Image Comparison

### Universal Image includes:
- **Languages**: Python, Node.js, Go, Rust, Java, Ruby, Swift, PHP, .NET, C/C++
- **Language Tools**: pyenv, nvm, cargo, gradle, maven, composer, etc.
- **Cloud CLIs**: AWS CLI, Google Cloud SDK, Azure CLI
- **Database Clients**: PostgreSQL, MySQL, Redis, MongoDB
- **Development Tools**: Docker, Bazel, editors, shells
- **API Frameworks**:NeutronAPI preinstalled
- **Size**: ~4-6GB compressed

### Minimal Image includes:
- **Languages**: Python 3.13, Node.js 22, Rust, Go, C/C++ (gcc/clang)
- **Essential Tools**: pip, npm, yarn, pnpm, cargo, rustfmt, clippy, make, cmake
- **API Frameworks**: NeutronAPI preinstalled
- **Version Control**: git
- **Size**: ~800MB-1.2GB compressed

## Pre-installed Languages & Tools (Universal)

### Programming Languages
- **Python**: pyenv, pip, pipx, poetry, uv (versions 3.10-3.13)
- **Node.js**: nvm, npm, yarn, pnpm, prettier, eslint, typescript (versions 18, 20, 22)
- **Go**: gopls, delve debugger
- **Rust**: cargo, rustfmt, clippy, sccache
- **Java**: OpenJDK 21, Gradle 8.14, Maven 3.9.6
- **Ruby**: rbenv, bundler, rails
- **Swift**: swiftly package manager
- **PHP**: composer
- **.NET**: SDK 8.0
- **C/C++**: clang, cmake, ninja, ccache

### Development Tools
- **Version Control**: git, git-lfs
- **Build Tools**: make, cmake, bazel
- **Containers**: docker, docker-compose
- **Editors**: vim, nano, emacs
- **Shell**: bash, zsh, fish, tmux, screen

### Cloud & Database Tools
- **Cloud CLIs**: AWS CLI, gcloud, Azure CLI
- **Database Clients**: psql, mysql, redis-cli, mongosh

### Python Async Frameworks
- **Uvicorn**: High-performance ASGI server
- **NeutronAPI**: Async-first API framework (installed latest)

## Building Locally

To build the images locally:

```bash
git clone https://github.com/layerbrain/machine-universal.git
cd machine-universal

# Build universal image
docker build -f images/universal/Dockerfile -t machine-universal:universal .

# Build minimal image  
docker build -f images/minimal/Dockerfile -t machine-universal:minimal .

# Always get the latest NeutronAPI (optional cache-bust)
# Add a changing build-arg to re-run the NeutronAPI install layer
docker build -f images/universal/Dockerfile \
  --build-arg NEUTRONAPI_REFRESH=$(date -u +%s) \
  -t machine-universal:universal-latest-neutron .
```

## Use Cases

### Universal Image
- **Multi-language Projects**: Full polyglot development support
- **CI/CD Pipelines**: Complete toolchain for complex builds
- **Educational Settings**: Complete development environment for students
- **Cloud Development**: Includes all major cloud provider CLIs and database clients

### Minimal Image  
- **Microservices**: Lightweight containers for specific language stacks
- **Resource-Constrained Environments**: Smaller footprint for limited resources
- **Fast Deployment**: Quicker container startup and deployment times
- **Core Development**: Focus on essential languages without bloat

## Contributing

We welcome contributions! Please feel free to submit issues or pull requests to help improve the Universal Machine.

## License

This project is open source and available under the [MIT License](LICENSE).

## NeutronAPI

High-performance Python framework built directly on Uvicorn with built-in database models, migrations, and background tasks. If you want Django that was built async-first, this is for you. Batteries-included async API framework with command-line management.

- Installation: `pip install neutronapi`
- In these images: NeutronAPI is preinstalled without version pinning so you get the latest available.
- Cache strategy: It’s installed at the end of the Docker build so earlier layers stay cached. To force fetching the newest release on rebuild, pass a changing build arg:

```bash
docker build -f images/universal/Dockerfile \
  --build-arg NEUTRONAPI_REFRESH=$(date -u +%s) \
  -t machine-universal:universal .
```

Quick start (typical ASGI pattern with Uvicorn):

```bash
# after adding your app module (e.g., app.py exposing `app`)
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

Refer to NeutronAPI’s documentation for its CLI and project scaffolding commands if available.
