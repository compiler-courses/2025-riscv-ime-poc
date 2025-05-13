#!/bin/bash
# Helper script to run SpaceMit SDK commands with proper environment
# This avoids the "cannot execute" errors

# Parse command and arguments
cmd="$1"
shift
args="$@"

# Get the SDK path from environment
sdk_path="${SDK_PATH}"

case "$cmd" in
    spine)
        echo "Running SpaceMit Spine..."
        # Directly call underlying command to avoid symlink issues
        bash "${sdk_path}/spacengine" "$args"
        ;;
    quick_start)
        echo "Running SpaceMit Quick Start..."
        bash "${sdk_path}/quick_start" "$args"
        ;;
    *)
        echo "Unknown command: $cmd"
        echo "Available commands: spine, quick_start"
        exit 1
        ;;
esac
