@ECHO OFF

rem Change the current working directory to the location of this batch script.
pushd "%~dp0"
copy /Y mushclient_prefs.sqlite.sample mushclient_prefs.sqlite > nul
start MUSHclient.exe
cd mapperproxy
python -B startmapper.py
rem Reset the working directory to it's previous value, before this batch script was run.
popd
