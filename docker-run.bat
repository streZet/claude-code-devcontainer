@echo off
setlocal enabledelayedexpansion

set VOLUME_ARGS=-v "%USERPROFILE%\.claude:/home/dev/.claude"
if exist "%USERPROFILE%\.gitconfig" (
    set VOLUME_ARGS=!VOLUME_ARGS! -v "%USERPROFILE%\.gitconfig:/home/dev/.gitconfig:ro"
)
if not exist "%USERPROFILE%\.config\gh-devcontainer" mkdir "%USERPROFILE%\.config\gh-devcontainer"
set VOLUME_ARGS=!VOLUME_ARGS! -v "%USERPROFILE%\.config\gh-devcontainer:/home/dev/.config/gh"
set CONTAINER_NAME=
set PROJECT_NAME=
set WORKDIR_ARGS=
set SECRET_ARGS=

set TOKEN_DIR=%USERPROFILE%\.config\claude-devcontainer
:parse_args
if "%~1"=="" goto run
if "%~1"=="--workspace" (
    set "WORKSPACE_PATH=%~2"
    if "!WORKSPACE_PATH:~-1!"=="\" set "WORKSPACE_PATH=!WORKSPACE_PATH:~0,-1!"
    if "!WORKSPACE_PATH:~-1!"=="/" set "WORKSPACE_PATH=!WORKSPACE_PATH:~0,-1!"
    for /f "delims=" %%S in ('powershell -NoProfile -Command "(Split-Path -Leaf '!WORKSPACE_PATH!') -replace '[^^a-zA-Z0-9._-]','-'"') do set PROJECT_NAME=%%S
    set VOLUME_ARGS=!VOLUME_ARGS! -v "!WORKSPACE_PATH!:/home/dev/!PROJECT_NAME!"
    set WORKDIR_ARGS=-w /home/dev/!PROJECT_NAME!
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
if "!CONTAINER_NAME!"=="" (
    if "!PROJECT_NAME!"=="" (
        set CONTAINER_NAME=claude-code-development
    ) else (
        set CONTAINER_NAME=claude-code-development_!PROJECT_NAME!
    )
)

docker container inspect !CONTAINER_NAME! >nul 2>&1
if %errorlevel%==0 (
    echo Container "!CONTAINER_NAME!" already exists:
    docker container inspect !CONTAINER_NAME! --format "  Image: {{.Config.Image}}  Status: {{.State.Status}}  Created: {{.Created}}"
    set TOKEN_FILE=
    for /f "tokens=1,* delims==" %%A in ('docker container inspect !CONTAINER_NAME! --format "{{range .Mounts}}{{.Destination}}={{.Source}}{{println}}{{end}}"') do (
        if "%%A"=="/run/secrets/claude_token" set "TOKEN_FILE=%%B"
    )
    if defined TOKEN_FILE if not exist "!TOKEN_FILE!" (
        if not defined CLAUDE_CODE_OAUTH_TOKEN (
            echo Error: token file "!TOKEN_FILE!" is missing and CLAUDE_CODE_OAUTH_TOKEN is not set.
            exit /b 1
        )
        echo Restoring token file "!TOKEN_FILE!"...
        call :write_token
    )
    echo.
    echo Starting existing container...
    docker start -ai !CONTAINER_NAME!
) else (
    if defined CLAUDE_CODE_OAUTH_TOKEN (
        if not exist "!TOKEN_DIR!" mkdir "!TOKEN_DIR!"
        set "TOKEN_FILE=!TOKEN_DIR!\!CONTAINER_NAME!.token"
        call :write_token
        set SECRET_ARGS=--mount type=bind,src="!TOKEN_FILE!",dst=/run/secrets/claude_token,readonly
    )
    docker run -it --name !CONTAINER_NAME! -p 3000:3000 !VOLUME_ARGS! !WORKDIR_ARGS! !SECRET_ARGS! claude-code-development
)
endlocal
exit /b

:write_token
powershell -NoProfile -Command "Set-Content -NoNewline -Path $env:TOKEN_FILE -Value $env:CLAUDE_CODE_OAUTH_TOKEN"
exit /b
