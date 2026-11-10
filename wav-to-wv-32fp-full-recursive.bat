@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: WAV -> WavPack (.wv), 32-bit float, NO noise floor gate (1 LEVEL DEEP)
:: Preserves all sample data including below -144 dBFS.
:: After encode, verifies lossless by SHA256 of float PCM (source vs WV).
:: Existing .wv outputs are skipped (never overwritten).

set "COUNT=0"
set "FAIL=0"
set "SKIPPED=0"

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
if /I not "%~x1"==".wav" goto :SkipArg
call :Convert "%~1"
goto :NextArg

:IsDir
call :ScanOneLevel "%~1"
goto :NextArg

:SkipArg
echo SKIP not a WAV: %~1

:NextArg
shift
goto :ArgLoop

:NoArgs
call :ScanOneLevel "%CD%"
goto :Done

:ScanOneLevel
for %%F in ("%~1\*.wav") do call :Convert "%%~fF"
for /d %%D in ("%~1\*") do (
  for %%F in ("%%~fD\*.wav") do call :Convert "%%~fF"
)
goto :eof

:Convert
set /a COUNT+=1
set "IN=%~f1"
set "OUT=%~dpn1.wv"
echo.
echo [!COUNT!] "!IN!"
echo     -^> "!OUT!"

if exist "!OUT!" (
  echo SKIP exists: "!OUT!"
  set /a SKIPPED+=1
  goto :eof
)

ffmpeg -hide_banner -n -i "!IN!" -vn -map 0:a:0 -c:a wavpack -sample_fmt fltp "!OUT!"
if errorlevel 1 goto :ConvertFail
if not exist "!OUT!" goto :ConvertFail

call :Verify "!IN!" "!OUT!"
if errorlevel 1 (
  echo VERIFY FAIL: float PCM hash mismatch - removing "!OUT!"
  del /f /q "!OUT!" >nul 2>&1
  goto :ConvertFail
)

echo OK  verified
goto :eof

:ConvertFail
echo FAILED: "!IN!"
set /a FAIL+=1
goto :eof

:Verify
set "H_IN="
set "H_OUT="
for /f "usebackq tokens=2 delims==" %%H in (`ffmpeg -hide_banner -nostats -i "%~1" -vn -map 0:a:0 -c:a pcm_f32le -f hash -hash sha256 - 2^>nul`) do set "H_IN=%%H"
for /f "usebackq tokens=2 delims==" %%H in (`ffmpeg -hide_banner -nostats -i "%~2" -vn -map 0:a:0 -c:a pcm_f32le -f hash -hash sha256 - 2^>nul`) do set "H_OUT=%%H"
if not defined H_IN exit /b 1
if not defined H_OUT exit /b 1
if /I not "!H_IN!"=="!H_OUT!" (
  echo       src  !H_IN!
  echo       wv   !H_OUT!
  exit /b 1
)
exit /b 0

:Done
echo.
if !COUNT! EQU 0 goto :NoneFound
echo Done. Converted: !COUNT!  Failed: !FAIL!  Skipped: !SKIPPED!
goto :Pause

:NoneFound
echo No WAV files found.
echo Drag WAV files/folders onto this script, or run it in a folder of WAVs.

:Pause
echo.
pause
exit /b !FAIL!
