@echo off
cls

rem Change the current working directory to the location of this batch script.
pushd "%~dp0"

rem A small delay is needed here so that NVDA will automatically speak the first line of output.
rem timeout /T 1 /NOBREAK >nul 2>&1
luajit.exe -e "require('socket'); socket.sleep(0.1)"

if exist "tempmapper" rd /S /Q "tempmapper"

if exist "mapper_proxy" (
	if "%1" NEQ "/CalledByScript" echo Checking for updates to the mapper.
) else (
	echo Mapper Proxy not found. This is normal for new installations.
)

luajit.exe update_checker.lua

if exist "mapper_proxy.zip" (
	echo Extracting files.
	unzip.exe -qq "mapper_proxy.zip" -d "tempmapper"
	for /D %%G in ("tempmapper\Mapper_Proxy_V*") DO xcopy "%%G" "mapper_proxy" /E /V /I /Q /R /Y
	rd /S /Q "tempmapper"
	del /F /Q "mapper_proxy.zip"
	echo Done.
	pause
) else (
	if "%1" NEQ "/CalledByScript" pause
)

rem Reset the working directory to it's previous value, before this batch script was run.
popd
