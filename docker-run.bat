@echo off

set VOLUME_ARGS=-v "%USERPROFILE%\.claude:/home/dev/.claude"
set CONTAINER_NAME=claude-code-development
set SSH_ARGS=

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
if "%~1"=="--ssh" (
    set SSH_ARGS=-v //./pipe/openssh-ssh-agent:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock
    shift
    goto parse_args
)
echo Unknown option: %~1
echo Usage: docker-run.bat [--workspace ^<path^>] [--name ^<container-name^>] [--ssh]
exit /b 1

:run
docker run -it --name %CONTAINER_NAME% -p 3000:3000 %VOLUME_ARGS% %SSH_ARGS% claude-code-development
