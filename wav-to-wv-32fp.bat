@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: WAV -> WavPack (.wv), 32-bit float, -144 dBFS noise floor
:: Usage:
::   Drag WAV file(s) and/or folders onto this script
::   Or run with no args to convert all *.wav in the current directory
::
:: Floor: samples below -144 dBFS are gated to silence (24-bit theoretical floor).
:: Threshold linear amplitude = 10^(-144/20) ~= 6.30957344e-8
:: Existing .wv outputs are skipped (never overwritten).

set "AF=agate=threshold=6.30957344e-8:range=0:ratio=9000:attack=0.01:release=0.01:knee=1:detection=peak"
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
for %%F in ("%~1\*.wav") do call :Convert "%%~fF"
goto :NextArg

:SkipArg
echo SKIP not a WAV: %~1

:NextArg
shift
goto :ArgLoop

:NoArgs
for %%F in ("*.wav") do call :Convert "%%~fF"
goto :Done

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

ffmpeg -hide_banner -n -i "!IN!" -vn -map 0:a:0 -af "!AF!" -c:a wavpack -sample_fmt fltp "!OUT!"
if errorlevel 1 (
  echo FAILED: "!IN!"
  set /a FAIL+=1
) else (
  echo OK
)
goto :eof

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
