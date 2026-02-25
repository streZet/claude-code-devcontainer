#!/bin/bash
docker run -it --name claude-code-development -p 3000:3000 -v "$(pwd):/home/dev/project" -v "$HOME/.claude:/home/dev/.claude" claude-code-development
