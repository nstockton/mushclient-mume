@ECHO OFF

rem Change the current working directory to the location of this batch script.
pushd "%~dp0"

for /F "delims=" %%i in ('dir /b /s "lua\tests\test_*.lua"') do (
	echo "Running tests in %%~ni"
	luajit.exe "%%i" --failure --output text
)

rem Reset the working directory to its previous value, before this batch script was run.
popd
