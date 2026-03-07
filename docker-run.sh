#!/bin/bash

VOLUME_ARGS="-v $HOME/.claude:/home/dev/.claude"
CONTAINER_NAME="claude-code-development"
SSH_ARGS=""

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
        --ssh)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                SSH_ARGS="-v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock"
            else
                SSH_ARGS="-v $SSH_AUTH_SOCK:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock"
            fi
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: docker-run.sh [--workspace <path>] [--name <container-name>] [--ssh]"
            exit 1
            ;;
    esac
done

if docker container inspect "$CONTAINER_NAME" > /dev/null 2>&1; then
    echo "Container \"$CONTAINER_NAME\" already exists:"
    docker ps -a --filter "name=^${CONTAINER_NAME}$" --format "  ID: {{.ID}}  Image: {{.Image}}  Status: {{.Status}}  Created: {{.CreatedAt}}"
    echo ""
    echo "Starting existing container..."
    docker start -ai "$CONTAINER_NAME"
else
    docker run -it --name "$CONTAINER_NAME" -p 3000:3000 $VOLUME_ARGS $SSH_ARGS claude-code-development
fi
