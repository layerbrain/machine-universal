#!/bin/bash

echo "=================================="
echo "Welcome to Layerbrain!"
echo "=================================="

# Run setup script
/opt/layerbrain/setup.sh

# If command is provided, execute it
if [ $# -gt 0 ]; then
    exec "$@"
else
    # Otherwise drop into interactive bash shell
    echo "Environment ready. Dropping you into a bash shell."
    exec bash --login
fi
