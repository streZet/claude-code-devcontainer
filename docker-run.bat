@echo off

set VOLUME_ARGS=-v "%USERPROFILE%\.claude:/home/dev/.claude"

if not "%~1"=="" (
    set VOLUME_ARGS=%VOLUME_ARGS% -v "%~1:/home/dev/workspace"
)

docker run -it --name claude-code-development -p 3000:3000 %VOLUME_ARGS% claude-code-development
