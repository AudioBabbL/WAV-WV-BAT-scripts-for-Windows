@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: WavPack (.wv) -> WAV, 32-bit float
:: After a successful convert, original WV is sent to the Recycle Bin.
:: Usage:
::   Drag WV file(s) and/or folders onto this script
::   Or run with no args to convert all *.wv in the current directory
::
:: Existing .wav outputs are skipped (never overwritten); WV is not recycled then.

set "COUNT=0"
set "FAIL=0"
set "SKIPPED=0"
set "RECYCLED=0"

where ffmpeg >nul 2>&1
if errorlevel 1 (
  echo ERROR: ffmpeg not found on PATH.
  pause
  exit /b 1
)

if "%~1"=="" goto :NoArgs

:ArgLoop
if "%~1"=="" goto :Done

if exist "%~1\" goto :IsDir
if /I not "%~x1"==".wv" goto :SkipArg
call :Convert "%~1"
goto :NextArg

:IsDir
for %%F in ("%~1\*.wv") do call :Convert "%%~fF"
goto :NextArg

:SkipArg
echo SKIP not a WV: %~1

:NextArg
shift
goto :ArgLoop

:NoArgs
for %%F in ("*.wv") do call :Convert "%%~fF"
goto :Done

:Convert
set /a COUNT+=1
set "IN=%~f1"
set "OUT=%~dpn1.wav"
echo.
echo [!COUNT!] "!IN!"
echo     -^> "!OUT!"

if exist "!OUT!" (
  echo SKIP exists: "!OUT!"
  set /a SKIPPED+=1
  goto :eof
)

ffmpeg -hide_banner -n -i "!IN!" -vn -map 0:a:0 -c:a pcm_f32le "!OUT!"
if errorlevel 1 goto :ConvertFail
if not exist "!OUT!" goto :ConvertFail

echo OK
call :Recycle "!IN!"
if errorlevel 1 (
  echo WARN: convert OK but could not recycle: "!IN!"
) else (
  echo Recycled original WV
  set /a RECYCLED+=1
)
goto :eof

:ConvertFail
echo FAILED: "!IN!"
set /a FAIL+=1
goto :eof

:Recycle
:: Pass path via env var so spaces / special chars are not re-split by PowerShell.
set "WV_RECYCLE_FILE=%~f1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName Microsoft.VisualBasic; if (-not (Test-Path -LiteralPath $env:WV_RECYCLE_FILE)) { exit 1 }; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:WV_RECYCLE_FILE, 'OnlyErrorDialogs', 'SendToRecycleBin'); if (Test-Path -LiteralPath $env:WV_RECYCLE_FILE) { exit 1 }"
set "WV_RC=!ERRORLEVEL!"
set "WV_RECYCLE_FILE="
exit /b !WV_RC!

:Done
echo.
if !COUNT! EQU 0 goto :NoneFound
echo Done. Converted: !COUNT!  Failed: !FAIL!  Skipped: !SKIPPED!  Recycled: !RECYCLED!
goto :Pause

:NoneFound
echo No WV files found.
echo Drag WV files/folders onto this script, or run it in a folder of WVs.

:Pause
echo.
pause
exit /b !FAIL!
