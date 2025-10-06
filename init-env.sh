#!/bin/bash
# Initialize environment for SSH sessions

# Go
export PATH="/usr/local/go/bin:$PATH"

# Rust
export PATH="/root/.cargo/bin:$PATH"

# Python (pyenv if exists)
if [ -d "/root/.pyenv" ]; then
    export PYENV_ROOT="/root/.pyenv"
    export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init - bash)" 2>/dev/null
fi

# Node (nvm if exists)
if [ -d "/root/.nvm" ]; then
    export NVM_DIR="/root/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" 2>/dev/null
fi

# Bun
if [ -d "/root/.bun" ]; then
    export BUN_INSTALL="/root/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Swift
if [ -d "/root/.local/share/swiftly" ]; then
    . /root/.local/share/swiftly/env.sh 2>/dev/null
fi

# Gradle & Maven
if [ -d "/opt/gradle" ]; then
    export GRADLE_HOME="/opt/gradle"
    export PATH="$GRADLE_HOME/bin:$PATH"
fi

if [ -d "/opt/maven" ]; then
    export MAVEN_HOME="/opt/maven"
    export PATH="$MAVEN_HOME/bin:$PATH"
fi

# .NET
if [ -d "/root/.dotnet" ]; then
    export DOTNET_ROOT="/root/.dotnet"
    export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"
fi

# pipx
export PATH="/root/.local/bin:$PATH"
