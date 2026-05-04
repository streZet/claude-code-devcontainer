#!/bin/bash

VOLUME_ARGS=(-v "$HOME/.claude:/home/dev/.claude")
CONTAINER_NAME=""
PROJECT_NAME=""
SSH_ARGS=()
WORKDIR_ARGS=()
SECRET_ARGS=()

if [[ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]]; then
    TOKEN_FILE=$(mktemp)
    chmod 600 "$TOKEN_FILE"
    printf '%s' "$CLAUDE_CODE_OAUTH_TOKEN" > "$TOKEN_FILE"
    SECRET_ARGS=(--mount "type=bind,src=$TOKEN_FILE,dst=/run/secrets/claude_token,readonly")
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --workspace)
            WORKSPACE_PATH="${2%/}"
            WORKSPACE_PATH="${WORKSPACE_PATH%\\}"
            PROJECT_NAME=$(basename "$WORKSPACE_PATH" | sed 's/[^a-zA-Z0-9._-]/-/g')
            VOLUME_ARGS+=(-v "$WORKSPACE_PATH:/home/dev/$PROJECT_NAME")
            WORKDIR_ARGS=(-w "/home/dev/$PROJECT_NAME")
            shift 2
            ;;
        --name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --ssh)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                SSH_ARGS=(-v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock)
            else
                SSH_ARGS=(-v "$SSH_AUTH_SOCK:/run/host-services/ssh-auth.sock" -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock)
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

if [[ -z "$CONTAINER_NAME" ]]; then
    if [[ -n "$PROJECT_NAME" ]]; then
        CONTAINER_NAME="claude-code-development_$PROJECT_NAME"
    else
        CONTAINER_NAME="claude-code-development"
    fi
fi

if docker container inspect "$CONTAINER_NAME" > /dev/null 2>&1; then
    echo "Container \"$CONTAINER_NAME\" already exists:"
    docker ps -a --filter "name=^${CONTAINER_NAME}$" --format "  ID: {{.ID}}  Image: {{.Image}}  Status: {{.Status}}  Created: {{.CreatedAt}}"
    echo ""
    echo "Starting existing container..."
    docker start -ai "$CONTAINER_NAME"
else
    docker run -it --name "$CONTAINER_NAME" -p 3000:3000 "${VOLUME_ARGS[@]}" "${SSH_ARGS[@]}" "${SECRET_ARGS[@]}" "${WORKDIR_ARGS[@]}" claude-code-development
fi
