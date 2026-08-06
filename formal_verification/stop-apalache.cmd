@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PORT=8822"
set "CLOSE_TERMINAL=0"

:parse_args
if "%~1"=="" goto :args_done
if /I "%~1"=="--close-terminal" (
  set "CLOSE_TERMINAL=1"
) else (
  set "PORT=%~1"
)
shift
goto :parse_args

:args_done

set "FOUND=0"
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%PORT% .*LISTENING"') do (
  if not defined SEEN_%%P (
    set "SEEN_%%P=1"
    set "FOUND=1"
    echo Stopping PID %%P on port %PORT%...
    taskkill /PID %%P /T /F >nul 2>nul
    if errorlevel 1 (
      echo Failed to stop PID %%P.
    ) else (
      echo Stopped PID %%P.
    )
  )
)

if "%FOUND%"=="0" (
  echo No process is listening on port %PORT%.
)

if "%CLOSE_TERMINAL%"=="1" (
  endlocal
  exit 0
)

endlocal
exit /b 0
