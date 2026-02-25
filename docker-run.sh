#!/bin/bash

VOLUME_ARGS="-v $HOME/.claude:/home/dev/.claude"
CONTAINER_NAME="claude-code-development"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --workspace)
            VOLUME_ARGS="$VOLUME_ARGS -v $2:/home/dev/workspace"
            shift 2
            ;;
        --name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: docker-run.sh [--workspace <path>] [--name <container-name>]"
            exit 1
            ;;
    esac
done

docker run -it --name "$CONTAINER_NAME" -p 3000:3000 $VOLUME_ARGS claude-code-development
