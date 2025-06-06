# universal-machine

A comprehensive, zero-configuration development environment container powered by Layerbrain.

This repository provides a universal base Docker image that includes all major programming languages and development tools pre-installed and ready to use. It's designed to eliminate environment setup friction and provide a consistent development experience across different projects and teams.

## Features

- **Multi-language support**: Python, Node.js, Go, Rust, Java, Ruby, Swift, PHP, .NET, and more
- **Pre-configured tools**: Package managers, linters, formatters, and build tools for each language
- **Cloud-ready**: AWS CLI, Google Cloud SDK, and Azure CLI pre-installed
- **Database clients**: PostgreSQL, MySQL, Redis, and MongoDB clients included
- **Zero setup**: Works out of the box with sensible defaults

## Quick Start

Pull and run the latest image:

```bash
docker pull ghcr.io/layerbrain/universal-machine:latest
```

Run with your project mounted:

```bash
# This mounts your current directory and drops you into an interactive shell
docker run --rm -it \
    -v $(pwd):/workspace/$(basename $(pwd)) \
    -w /workspace/$(basename $(pwd)) \
    ghcr.io/layerbrain/universal-machine:latest
```

## Customizing Runtime Versions

The universal-machine supports dynamic configuration of language runtimes through environment variables. Set any of the following `LAYERBRAIN_ENV_*` variables to customize your environment:

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
    ghcr.io/layerbrain/universal-machine:latest
```

## Pre-installed Languages & Tools

### Programming Languages
- **Python**: pyenv, pip, pipx, poetry, uv
- **Node.js**: nvm, npm, yarn, pnpm, prettier, eslint, typescript
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

## Building Locally

To build the image locally:

```bash
git clone https://github.com/layerbrain/universal-machine.git
cd universal-machine
docker build -t universal-machine .
```

## Use Cases

- **Consistent Development Environment**: Ensure all team members use the same tools and versions
- **CI/CD Pipelines**: Use as a base image for running tests and builds
- **Educational Settings**: Provide students with a complete development environment
- **Rapid Prototyping**: Start coding immediately without setup overhead
- **Multi-language Projects**: Work on polyglot applications without switching environments

## Contributing

We welcome contributions! Please feel free to submit issues or pull requests to help improve the universal-machine.

## License

This project is open source and available under the [MIT License](LICENSE).
