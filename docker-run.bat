@echo off
docker run -it --name claude-code-development -p 3000:3000 -v "%cd%:/home/dev/project" -v "%USERPROFILE%\.claude:/home/dev/.claude" claude-code-development
