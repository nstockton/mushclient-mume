@ECHO OFF

rem Change the current working directory to the location of this batch script.
pushd "%~dp0"
copy /Y mushclient_prefs.sqlite.sample mushclient_prefs.sqlite > nul
copy /Y MUSHclient.ini.sample MUSHclient.ini > nul
if not exist "worlds\mume\mume.mcl" copy /Y worlds\mume\mume.mcl.sample worlds\mume\mume.mcl > nul
if not exist "worlds\angband\angband.mcl" copy /Y worlds\angband\angband.mcl.sample worlds\angband\angband.mcl > nul
start MUSHclient.exe
cd mapperproxy
python -B startmapper.py raw
rem Reset the working directory to it's previous value, before this batch script was run.
popd
