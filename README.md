# Universal Machine

A comprehensive, zero-configuration development environment container with all major programming languages and modern CLI tools.

## Features

- **Multi-language support**: Python, Node.js, Go, Rust, Java, Ruby, Swift, C/C++
- **Modern CLI tools**: fd, bat, eza, dust, broot, sd, ripgrep
- **Pre-configured tools**: Package managers, linters, formatters, and build tools
- **Cloud-ready**: AWS CLI pre-installed
- **Database clients**: PostgreSQL and MySQL clients included
- **Zero setup**: Works out of the box with sensible defaults
- **Async API ready**: Includes Uvicorn and NeutronAPI for high-performance Python APIs

## Quick Start

```bash
# AMD64
docker pull ghcr.io/layerbrain/machine-universal:universal-amd64-latest

# ARM64
docker pull ghcr.io/layerbrain/machine-universal:universal-arm64-latest
```

Run with your project mounted:

```bash
docker run --rm -it \
    -v $(pwd):/workspace/$(basename $(pwd)) \
    -w /workspace/$(basename $(pwd)) \
    ghcr.io/layerbrain/machine-universal:universal-amd64-latest
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

The machine-universal supports dynamic configuration of language runtimes through environment variables:

| Environment Variable | Description | Available Versions | Default |
|---------------------|-------------|-------------------|---------|
| `LAYERBRAIN_ENV_PYTHON_VERSION` | Python version | 3.12, 3.13 | 3.13 |
| `LAYERBRAIN_ENV_NODE_VERSION` | Node.js version | 20, 22 | 22 |
| `LAYERBRAIN_ENV_RUST_VERSION` | Rust toolchain | stable, beta, nightly | stable |
| `LAYERBRAIN_ENV_GO_VERSION` | Go version | 1.23.x | 1.23.8 |
| `LAYERBRAIN_ENV_SWIFT_VERSION` | Swift version | 6.1 | 6.1 |
| `LAYERBRAIN_ENV_JAVA_VERSION` | Java version | 21 | 21 |
| `LAYERBRAIN_ENV_RUBY_VERSION` | Ruby version | 3.3 | 3.3 |

### Example with custom versions:

```bash
docker run --rm -it \
    -e LAYERBRAIN_ENV_PYTHON_VERSION=3.12 \
    -e LAYERBRAIN_ENV_NODE_VERSION=20 \
    -e LAYERBRAIN_ENV_RUST_VERSION=nightly \
    -v $(pwd):/workspace/$(basename $(pwd)) \
    -w /workspace/$(basename $(pwd)) \
    ghcr.io/layerbrain/machine-universal:universal-amd64-latest
```

## What's Included

### Programming Languages
- **Python**: pyenv (3.12, 3.13), pip, pipx, poetry, uv, ruff, mypy
- **Node.js**: nvm (20, 22), npm, yarn, pnpm, prettier, eslint, typescript, Bun
- **Go**: gopls, delve debugger
- **Rust**: cargo, rustfmt, clippy, sccache
- **Java**: OpenJDK 21, Gradle 8.14, Maven 3.9.6
- **Ruby**: rbenv, bundler
- **Swift**: swiftly package manager
- **C/C++**: clang, cmake, ninja, ccache, gdb

### Modern CLI Tools (Rust-based)
- **fd**: Fast find replacement
- **bat**: Cat with syntax highlighting
- **eza**: Modern ls replacement
- **dust**: Intuitive du replacement
- **broot**: Interactive tree navigator
- **sd**: Fast sed replacement
- **ripgrep**: Fast grep replacement

### Additional Tools
- **ffmpeg**: Media processing
- **tidy**: HTML validator
- **biome**: Fast JS/TS linter

### Development Tools
- **Version Control**: git, git-lfs
- **Build Tools**: make, cmake, ninja
- **Containers**: docker, docker-compose
- **Editors**: vim, nano
- **Shell**: bash, tmux, htop, ncdu, tree

### Cloud & Database Tools
- **Cloud CLIs**: AWS CLI
- **Database Clients**: psql, mysql

### Python Async Frameworks
- **Uvicorn**: High-performance ASGI server
- **asyncpg, aiosqlite, aiohttp, asyncssh, httpx, uvloop**
- **NeutronAPI**: Async-first API framework (installed latest)

## Building Locally

```bash
git clone https://github.com/layerbrain/machine-universal.git
cd machine-universal

# Build image
docker build -f images/universal/Dockerfile -t machine-universal .

# Always get the latest NeutronAPI (optional cache-bust)
docker build -f images/universal/Dockerfile \
  --build-arg NEUTRONAPI_REFRESH=$(date -u +%s) \
  -t machine-universal:latest .
```

## Contributing

We welcome contributions! Please feel free to submit issues or pull requests to help improve the Universal Machine.

## License

This project is open source and available under the [MIT License](LICENSE).

## NeutronAPI

High-performance Python framework built directly on Uvicorn with built-in database models, migrations, and background tasks. Batteries-included async API framework with command-line management.

- Installation: `pip install neutronapi`
- In this image: NeutronAPI is preinstalled without version pinning so you get the latest available.

Quick start:

```bash
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```
