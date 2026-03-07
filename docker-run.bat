@echo off

set VOLUME_ARGS=-v "%USERPROFILE%\.claude:/home/dev/.claude"
set CONTAINER_NAME=claude-code-development
:parse_args
if "%~1"=="" goto run
if "%~1"=="--workspace" (
    set VOLUME_ARGS=%VOLUME_ARGS% -v "%~2:/home/dev/workspace"
    shift
    shift
    goto parse_args
)
if "%~1"=="--name" (
    set CONTAINER_NAME=%~2
    shift
    shift
    goto parse_args
)
echo Unknown option: %~1
echo Usage: docker-run.bat [--workspace ^<path^>] [--name ^<container-name^>]
exit /b 1

:run
docker container inspect %CONTAINER_NAME% >nul 2>&1
if %errorlevel%==0 (
    echo Container "%CONTAINER_NAME%" already exists:
    docker ps -a --filter "name=^%CONTAINER_NAME%$" --format "  ID: {{.ID}}  Image: {{.Image}}  Status: {{.Status}}  Created: {{.CreatedAt}}"
    echo.
    echo Starting existing container...
    docker start -ai %CONTAINER_NAME%
) else (
    docker run -it --name %CONTAINER_NAME% -p 3000:3000 %VOLUME_ARGS% claude-code-development
)
