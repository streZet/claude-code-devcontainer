#!/bin/bash

VOLUME_ARGS=(-v "$HOME/.claude:/home/dev/.claude")
if [[ -f "$HOME/.gitconfig" ]]; then
    VOLUME_ARGS+=(-v "$HOME/.gitconfig:/home/dev/.gitconfig:ro")
fi
mkdir -p "$HOME/.config/gh-devcontainer"
VOLUME_ARGS+=(-v "$HOME/.config/gh-devcontainer:/home/dev/.config/gh")
VOLUME_ARGS+=(-v claude-devcontainer-mise:/home/dev/.local/share/mise)
CONTAINER_NAME=""
PROJECT_NAME=""
SSH_ARGS=()
WORKDIR_ARGS=()
SECRET_ARGS=()
RECREATE=false
PORT=""
HOST_PORT=""
PORT_RANGE_START=3000
PORT_RANGE_END=3100

TOKEN_DIR="$HOME/.config/claude-devcontainer"

write_token() {
    mkdir -p "$(dirname "$1")"
    printf '%s' "$CLAUDE_CODE_OAUTH_TOKEN" > "$1"
    chmod 600 "$1"
}

is_port_free() {
    [[ -z "$(docker ps -q --filter "publish=$1")" ]] || return 1
    ! (exec 3<>"/dev/tcp/127.0.0.1/$1") 2> /dev/null
}

resolve_port() {
    if [[ -n "$PORT" ]]; then
        if ! is_port_free "$PORT"; then
            echo "Error: port $PORT is already in use."
            return 1
        fi
        HOST_PORT="$PORT"
        return 0
    fi
    local candidate
    for ((candidate = PORT_RANGE_START; candidate <= PORT_RANGE_END; candidate++)); do
        if is_port_free "$candidate"; then
            HOST_PORT="$candidate"
            return 0
        fi
    done
    echo "Error: no free port in range $PORT_RANGE_START-$PORT_RANGE_END."
    return 1
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
        --recreate)
            RECREATE=true
            shift
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: docker-run.sh [--workspace <path>] [--name <container-name>] [--port <host-port>] [--ssh] [--recreate]"
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

if [[ "$RECREATE" == true ]] && docker container inspect "$CONTAINER_NAME" > /dev/null 2>&1; then
    echo "Removing container \"$CONTAINER_NAME\"..."
    docker rm -f "$CONTAINER_NAME" > /dev/null || exit 1
fi

if docker container inspect "$CONTAINER_NAME" > /dev/null 2>&1; then
    echo "Container \"$CONTAINER_NAME\" already exists:"
    docker container inspect "$CONTAINER_NAME" --format "  Image: {{.Config.Image}}  Status: {{.State.Status}}  Created: {{.Created}}"
    TOKEN_FILE=$(docker container inspect "$CONTAINER_NAME" --format '{{range .Mounts}}{{if eq .Destination "/run/secrets/claude_token"}}{{.Source}}{{end}}{{end}}')
    if [[ -n "$TOKEN_FILE" ]]; then
        if [[ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]]; then
            echo "Updating token file \"$TOKEN_FILE\"..."
            write_token "$TOKEN_FILE"
        elif [[ ! -f "$TOKEN_FILE" ]]; then
            echo "Error: token file \"$TOKEN_FILE\" is missing and CLAUDE_CODE_OAUTH_TOKEN is not set."
            exit 1
        fi
    fi
    echo ""
    if [[ "$(docker container inspect "$CONTAINER_NAME" --format '{{.State.Running}}')" == "true" ]]; then
        echo "Container is running, opening a new shell..."
        docker exec -it "$CONTAINER_NAME" bash
    else
        echo "Starting existing container..."
        docker start -ai "$CONTAINER_NAME"
    fi
else
    resolve_port || exit 1
    if [[ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]]; then
        TOKEN_FILE="$TOKEN_DIR/$CONTAINER_NAME.token"
        write_token "$TOKEN_FILE"
        SECRET_ARGS=(--mount "type=bind,src=$TOKEN_FILE,dst=/run/secrets/claude_token,readonly")
    fi
    echo "Host port: $HOST_PORT -> container port 3000"
    docker run -it --name "$CONTAINER_NAME" -p "$HOST_PORT:3000" "${VOLUME_ARGS[@]}" "${SSH_ARGS[@]}" "${SECRET_ARGS[@]}" "${WORKDIR_ARGS[@]}" claude-code-development
fi
