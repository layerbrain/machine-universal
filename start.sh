#!/bin/bash

echo "=================================="
echo "Welcome to Layerbrain!!!"
echo "=================================="

# Run setup script
/opt/layerbrain/setup.sh

# Resolve the root user's home directory in a cross-platform way.
ROOT_HOME="$(getent passwd root 2>/dev/null | cut -d: -f6)"
if [ -z "$ROOT_HOME" ]; then
    ROOT_HOME="$(eval echo ~root)"
fi
ROOT_SSH_DIR="${ROOT_HOME}/.ssh"

# Configure SSH if credentials provided
if [ -n "$SSH_PUBLIC_KEY" ]; then
    mkdir -p "$ROOT_SSH_DIR"
    chmod 700 "$ROOT_SSH_DIR"
    echo "$SSH_PUBLIC_KEY" > "${ROOT_SSH_DIR}/authorized_keys"
    chmod 600 "${ROOT_SSH_DIR}/authorized_keys"
    echo "SSH public key configured."
fi

# Start SSH server
if [ -n "$SSH_PUBLIC_KEY" ]; then
    # Create SSH wrapper script
    cat > /usr/local/bin/ssh-wrapper.sh << 'WRAPPER_EOF'
#!/bin/bash
source /opt/layerbrain/init-env.sh 2>/dev/null || true
if [ -z "$SSH_ORIGINAL_COMMAND" ]; then
    exec $SHELL -l
else
    exec $SHELL -c "$SSH_ORIGINAL_COMMAND"
fi
WRAPPER_EOF
    chmod +x /usr/local/bin/ssh-wrapper.sh

    # Configure sshd to use wrapper for all commands
    echo 'ForceCommand /usr/local/bin/ssh-wrapper.sh' >> /etc/ssh/sshd_config

    /usr/sbin/sshd
    echo "SSH server started on port 22."

    # If command is provided, execute it
    if [ $# -gt 0 ]; then
        exec "$@"
    else
        # Run sshd in foreground to keep container alive
        echo "SSH server running. Container will stay alive."
        exec tail -f /dev/null
    fi
else
    # No SSH configured, run command or bash
    if [ $# -gt 0 ]; then
        exec "$@"
    else
        echo "Environment ready. Dropping you into a bash shell."
        exec bash --login
    fi
fi
