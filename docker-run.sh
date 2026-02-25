#!/bin/bash

VOLUME_ARGS="-v $HOME/.claude:/home/dev/.claude"
CONTAINER_NAME="${2:-claude-code-development}"

if [ -n "$1" ]; then
    VOLUME_ARGS="$VOLUME_ARGS -v $1:/home/dev/workspace"
fi

docker run -it --name "$CONTAINER_NAME" -p 3000:3000 $VOLUME_ARGS claude-code-development
