@ECHO OFF

cls

rem Change the current working directory to the location of this batch script.
pushd "%~dp0"

copy /Y mushclient_prefs.sqlite.sample mushclient_prefs.sqlite >nul
copy /Y MUSHclient.ini.sample MUSHclient.ini >nul
if not exist "worlds\mume\mume.mcl" copy /Y worlds\mume\mume.mcl.sample worlds\mume\mume.mcl >nul

rem Check for a new version of the update script before trying to update the mapper.
luajit.exe update_checker.lua /CalledByScript /update
rem now check for updates to the mapper.
luajit.exe update_checker.lua /CalledByScript

if exist "mapper_proxy" (
	if exist "mapper_proxy\mapper_ready.ignore" del /F /Q "mapper_proxy\mapper_ready.ignore"
	start MUSHclient.exe
	cd mapper_proxy
	echo Running the mapper.
	"Mapper Proxy.exe" --format raw
) else (
	echo Error: failed to start because the mapper was not found.
	pause
)

rem Reset the working directory to its previous value, before this batch script was run.
popd
