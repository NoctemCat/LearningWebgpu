@echo off

if [%1]==[] goto usage
if [%2]==[] goto usage

@setlocal enableextensions enabledelayedexpansion
set str1=%1

@REM If emscripten
if x%str1:emscripten=%==x%str1% goto not-emscripten
start "" http://localhost:8000/
python -m http.server -d build/%str1%/out
goto :eof

@REM If executable
:not-emscripten
%2
goto :eof

endlocal

goto :eof
:usage
@echo Expected type
exit /B 1
