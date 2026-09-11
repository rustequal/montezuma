if "%1"=="" goto clean
if "%1"=="KBD" goto kbd
if "%1"=="kbd" goto kbd
echo BUILD -- assemble MX4C.COM with MASM 1.25
echo.
echo   BUILD       the original sources
echo   BUILD KBD   the same sources with PATCH\KBDFIX.DIF applied
echo.
echo The build runs in BUILD\ and writes nothing outside it.
goto end
:clean
echo Building the original sources.
goto copy
:kbd
echo Building with the keyboard patch.
:copy
if not exist BUILD\NUL mkdir BUILD
copy TOOLS\MASM\*.EXE BUILD >NUL
copy SRC\*.* BUILD >NUL
if not "%1"=="" goto patch
cd BUILD
goto make
:patch
copy TOOLS\PATCH.COM BUILD >NUL
copy PATCH\KBDFIX.DIF BUILD >NUL
cd BUILD
PATCH APPLY KBDFIX.DIF
if errorlevel 1 goto failed
del PATCH.COM
del KBDFIX.DIF
:make
call MAKEIT.BAT
cd ..
echo.
echo Done: BUILD\MX4C.COM
goto end
:failed
del PATCH.COM
del KBDFIX.DIF
cd ..
echo.
echo The patch did not apply. Nothing was built.
:end
