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
set RECREATE=
set PORT=
set HOST_PORT=
set PORT_RANGE_START=3000
set PORT_RANGE_END=3100

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
if "%~1"=="--recreate" (
    set RECREATE=1
    shift
    goto parse_args
)
if "%~1"=="--port" (
    set "PORT=%~2"
    shift
    shift
    goto parse_args
)
echo Unknown option: %~1
echo Usage: docker-run.bat [--workspace ^<path^>] [--name ^<container-name^>] [--port ^<host-port^>] [--recreate]
exit /b 1

:run
if "!CONTAINER_NAME!"=="" (
    if "!PROJECT_NAME!"=="" (
        set CONTAINER_NAME=claude-code-development
    ) else (
        set CONTAINER_NAME=claude-code-development_!PROJECT_NAME!
    )
)

if defined RECREATE (
    docker container inspect !CONTAINER_NAME! >nul 2>&1 && (
        echo Removing container "!CONTAINER_NAME!"...
        docker rm -f !CONTAINER_NAME! >nul || exit /b 1
    )
)

docker container inspect !CONTAINER_NAME! >nul 2>&1
if errorlevel 1 (
    call :resolve_port
    if errorlevel 1 exit /b 1
)

docker container inspect !CONTAINER_NAME! >nul 2>&1
if %errorlevel%==0 (
    echo Container "!CONTAINER_NAME!" already exists:
    docker container inspect !CONTAINER_NAME! --format "  Image: {{.Config.Image}}  Status: {{.State.Status}}  Created: {{.Created}}"
    set TOKEN_FILE=
    for /f "tokens=1,* delims==" %%A in ('docker container inspect !CONTAINER_NAME! --format "{{range .Mounts}}{{.Destination}}={{.Source}}{{println}}{{end}}"') do (
        if "%%A"=="/run/secrets/claude_token" set "TOKEN_FILE=%%B"
    )
    if defined TOKEN_FILE (
        if defined CLAUDE_CODE_OAUTH_TOKEN (
            echo Updating token file "!TOKEN_FILE!"...
            call :write_token
        ) else if not exist "!TOKEN_FILE!" (
            echo Error: token file "!TOKEN_FILE!" is missing and CLAUDE_CODE_OAUTH_TOKEN is not set.
            exit /b 1
        )
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
    echo Host port: !HOST_PORT! -^> container port 3000
    docker run -it --name !CONTAINER_NAME! -p !HOST_PORT!:3000 !VOLUME_ARGS! !WORKDIR_ARGS! !SECRET_ARGS! claude-code-development
)
endlocal
exit /b

:write_token
powershell -NoProfile -Command "Set-Content -NoNewline -Path $env:TOKEN_FILE -Value $env:CLAUDE_CODE_OAUTH_TOKEN"
exit /b

:resolve_port
if defined PORT (
    call :is_port_free !PORT!
    if errorlevel 1 (
        echo Error: port !PORT! is already in use.
        exit /b 1
    )
    set "HOST_PORT=!PORT!"
    exit /b 0
)
set /a CANDIDATE=PORT_RANGE_START
:resolve_port_loop
call :is_port_free !CANDIDATE!
if not errorlevel 1 (
    set "HOST_PORT=!CANDIDATE!"
    exit /b 0
)
set /a CANDIDATE+=1
if !CANDIDATE! gtr !PORT_RANGE_END! (
    echo Error: no free port in range !PORT_RANGE_START!-!PORT_RANGE_END!.
    exit /b 1
)
goto resolve_port_loop

:is_port_free
netstat -ano | findstr /R /C:":%~1 .*LISTENING" >nul
if errorlevel 1 exit /b 0
exit /b 1
