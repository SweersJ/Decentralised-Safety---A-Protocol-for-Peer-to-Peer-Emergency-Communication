@rem ============================================================================
@rem verify.cmd - Apalache Specification Verification Launcher
@rem ============================================================================
@rem
@rem PURPOSE:
@rem   Manages the lifecycle of an Apalache verification server and runs
@rem   formal verification and TLA+ compilation using Quint.
@rem
@rem   Solution for spawn EINVAL error when running .bat files on Windows
@rem   in the apalache.js file. On Windows, .bat files require shell: true
@rem   to be executable (spawn EINVAL otherwise).
@rem
@rem FEATURES:
@rem   - Automatically starts an Apalache server if not already running
@rem   - Reuses existing server instances for efficiency
@rem   - Accepts optional Quint verification arguments
@rem   - Supports --keep-server flag to maintain server after verification
@rem   - Supports --close-terminal to close the calling cmd.exe when finished
@rem   - Validates spec file and Apalache binary existence before execution
@rem
@rem USAGE:
@rem   verify.cmd <spec-file> [quint-args...] [--keep-server] [--close-terminal]
@rem
@rem PARAMETERS:
@rem   spec-file     Path to the .qnt specification file to verify
@rem   quint-args    Optional arguments passed to quint verify command
@rem   --keep-server Keep the Apalache server running after verification
@rem   --close-terminal Close the calling cmd.exe after verification
@rem   --compile     Compile the spec to TLA+ instead of verifying it
@rem
@rem EXAMPLES:
@rem   verify.cmd versions/00-test/bank.qnt --invariant=no_negatives
@rem   verify.cmd versions/01-02/batch.qnt --temporal=property --keep-server
@rem   verify.cmd versions/01-02/batch.qnt --backend tlc --temporal=property
@rem
@rem ENVIRONMENT:
@rem   PORT              Server port (default: 8822)
@rem   SERVER            Server endpoint (default: localhost:8822)
@rem   APALACHE_BIN      Path to apalache-mc.bat binary
@rem
@rem ============================================================================

@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PORT=8822"
set "SERVER=localhost:%PORT%"
set "KEEP_SERVER=0"
set "CLOSE_TERMINAL=0"
set "COMPILE=0"
set "SCRIPT_STARTED_SERVER=0"
@rem default: 0.56.1, options: 0.56.1, 0.59.1-SNAPSHOT, powsetfilter
set "APALACHE_VERSION=powsetfilter"
set "APALACHE_BIN=%USERPROFILE%\.quint\apalache-dist-%APALACHE_VERSION%\apalache\bin\apalache-mc.bat"

if /I "%~1"=="-h" goto :usage
if /I "%~1"=="--help" goto :usage

if "%~1"=="" goto :usage
set "SPEC=%~1"
shift

set "QUINT_ARGS="
:parse_args
if "%~1"=="" goto :args_done
if /I "%~1"=="--keep-server" (
  set "KEEP_SERVER=1"
) else if /I "%~1"=="--close-terminal" (
  set "CLOSE_TERMINAL=1"
) else if /I "%~1"=="--compile" (
  set "COMPILE=1"
) else (
  set "QUINT_ARGS=%QUINT_ARGS% %~1"
)
shift
goto :parse_args

:args_done

if not exist "%SPEC%" (
  echo Spec file not found: "%SPEC%"
  goto :usage
)

if not exist "%APALACHE_BIN%" (
  echo Apalache launcher not found:
  echo   %APALACHE_BIN%
  echo Run this once to download it:
  echo   quint verify "%SPEC%"
  exit /b 1
)

call :is_listening %PORT%
if errorlevel 1 (
  echo Starting Apalache server on port %PORT%...
  start "" /b cmd /d /c call "%APALACHE_BIN%" server --port=%PORT%
  call :wait_for_port %PORT% 30
  if errorlevel 1 (
    echo Failed to start Apalache server on port %PORT%.
    call :stop_port_pids %PORT%
    exit /b 1
  )
  set "SCRIPT_STARTED_SERVER=1"
) else (
  echo Reusing existing Apalache server on port %PORT%.
)

if "%COMPILE%"=="1" (
  call quint compile "%SPEC%" --target tlaplus --server-endpoint=%SERVER% %QUINT_ARGS%
) else (
  echo Running verification for "%SPEC%" with arguments "%QUINT_ARGS%"...
  call quint verify "%SPEC%" --server-endpoint=%SERVER% %QUINT_ARGS%
)
set "VERIFY_EXIT=%ERRORLEVEL%"

if "%SCRIPT_STARTED_SERVER%"=="1" (
  if "%KEEP_SERVER%"=="1" (
    echo Keeping Apalache server running on port %PORT%.
  ) else (
    echo Auto-closing Apalache server on port %PORT%...
    call :stop_port_pids %PORT%
  )
)

if "%CLOSE_TERMINAL%"=="1" (
  endlocal
  exit %VERIFY_EXIT%
)

endlocal
exit /b %VERIFY_EXIT%

@rem :usage
@rem   Displays usage information for the verify.cmd script
@rem   Parameters:
@rem     None
@rem   Return:
@rem     exit /b 1
:usage
echo Usage:
echo   verify.cmd [spec-file] [quint-args] [--keep-server] [--close-terminal]
echo .
echo Examples:
echo   cmd /c verify.cmd versions/00/bank.qnt --invariant=no_negatives
echo   cmd /c verify.cmd versions/00/bank.qnt --invariant=no_negatives --keep-server
echo   cmd /c verify.cmd versions/01/batch/batch.qnt --temporal=pending_ack_is_eventually_cleared
echo   cmd /c verify.cmd versions/01/batch/batch.qnt --temporal=pending_ack_is_eventually_cleared --keep-server
echo      Note: WARNING: Apalache has experimental support for temporal properties and might give incorrect results.
echo            Consider using --backend tlc, which fully supports temporal properties.
echo   cmd /c verify.cmd versions/01/batch/batch.qnt --backend tlc --temporal=pending_ack_is_eventually_cleared
echo      Note: WARNING: Unbounded model checking might take a long time.
echo   cmd /c verify.cmd versions/01/batch/batch.qnt --backend tlc --temporal=pending_ack_is_eventually_cleared --keep-server
exit /b 1

@rem :is_listening
@rem   Checks if a port is listening for connections
@rem   Parameters:
@rem     %%1 - Port number to check
@rem   Return:
@rem     exit /b 0 if port is listening
@rem     exit /b 1 if port is not listening
:is_listening
netstat -ano | findstr /R /C:":%~1 .*LISTENING" >nul 2>nul
if %ERRORLEVEL%==0 (
  exit /b 0
) else (
  exit /b 1
)

@rem :wait_for_port
@rem   Waits for a port to become available (listening)
@rem   Parameters:
@rem     %%1 - Port number to wait for
@rem     %%2 - Maximum number of retry attempts
@rem   Return:
@rem     exit /b 0 if port becomes listening
@rem     exit /b 1 if timeout reached without port listening
@rem   Notes:
@rem     Retries every 1 second
:wait_for_port
set /a _tries=%~2
:wait_loop
call :is_listening %~1
if %ERRORLEVEL%==0 exit /b 0
if %_tries% LEQ 0 exit /b 1
set /a _tries-=1
ping -n 2 127.0.0.1 >nul 2>&1
goto wait_loop

@rem :stop_port_pids
@rem   Terminates all processes listening on a specified port
@rem   Parameters:
@rem     %%1 - Port number to stop processes on
@rem   Return:
@rem     exit /b 0 (always succeeds)
@rem   Notes:
@rem     Uses SEEN_ flags to avoid killing the same PID multiple times
:stop_port_pids
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%~1 .*LISTENING"') do (
  if not defined SEEN_%%P (
    set "SEEN_%%P=1"
    taskkill /PID %%P /T /F >nul 2>nul
  )
)
exit /b 0
