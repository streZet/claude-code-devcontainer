#!/bin/bash

VOLUME_ARGS="-v $HOME/.claude:/home/dev/.claude"

if [ -n "$1" ]; then
    VOLUME_ARGS="$VOLUME_ARGS -v $1:/home/dev/workspace"
fi

docker run -it --name claude-code-development -p 3000:3000 $VOLUME_ARGS claude-code-development
