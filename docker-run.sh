#!/bin/bash

VOLUME_ARGS=(-v "$HOME/.claude:/home/dev/.claude")
if [[ -f "$HOME/.gitconfig" ]]; then
    VOLUME_ARGS+=(-v "$HOME/.gitconfig:/home/dev/.gitconfig:ro")
fi
mkdir -p "$HOME/.config/gh-devcontainer"
VOLUME_ARGS+=(-v "$HOME/.config/gh-devcontainer:/home/dev/.config/gh")
CONTAINER_NAME=""
PROJECT_NAME=""
SSH_ARGS=()
WORKDIR_ARGS=()
SECRET_ARGS=()

TOKEN_DIR="$HOME/.config/claude-devcontainer"

write_token() {
    mkdir -p "$(dirname "$1")"
    printf '%s' "$CLAUDE_CODE_OAUTH_TOKEN" > "$1"
    chmod 600 "$1"
}

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
    docker container inspect "$CONTAINER_NAME" --format "  Image: {{.Config.Image}}  Status: {{.State.Status}}  Created: {{.Created}}"
    TOKEN_FILE=$(docker container inspect "$CONTAINER_NAME" --format '{{range .Mounts}}{{if eq .Destination "/run/secrets/claude_token"}}{{.Source}}{{end}}{{end}}')
    if [[ -n "$TOKEN_FILE" && ! -f "$TOKEN_FILE" ]]; then
        if [[ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]]; then
            echo "Error: token file \"$TOKEN_FILE\" is missing and CLAUDE_CODE_OAUTH_TOKEN is not set."
            exit 1
        fi
        echo "Restoring token file \"$TOKEN_FILE\"..."
        write_token "$TOKEN_FILE"
    fi
    echo ""
    echo "Starting existing container..."
    docker start -ai "$CONTAINER_NAME"
else
    if [[ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]]; then
        TOKEN_FILE="$TOKEN_DIR/$CONTAINER_NAME.token"
        write_token "$TOKEN_FILE"
        SECRET_ARGS=(--mount "type=bind,src=$TOKEN_FILE,dst=/run/secrets/claude_token,readonly")
    fi
    docker run -it --name "$CONTAINER_NAME" -p 3000:3000 "${VOLUME_ARGS[@]}" "${SSH_ARGS[@]}" "${SECRET_ARGS[@]}" "${WORKDIR_ARGS[@]}" claude-code-development
fi
