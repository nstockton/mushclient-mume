@ECHO OFF

rem Change the current working directory to the location of this batch script.
pushd "%~dp0"
copy /Y mushclient_prefs.sqlite.sample mushclient_prefs.sqlite > nul
copy /Y MUSHclient.ini.sample MUSHclient.ini > nul
if not exist "worlds\mume\mume.mcl" copy /Y worlds\mume\mume.mcl.sample worlds\mume\mume.mcl > nul
start MUSHclient.exe
cd mapperproxy
for %%x in (pypy.exe) do (
	if not [%%~$PATH:x]==[] (
		echo "Running mapper with PyPy."
		pypy.exe -B startmapper.py raw
		goto :finished
	)
)
for %%x in (python.exe) do (
	if not [%%~$PATH:x]==[] (
		echo "Running mapper with Python."
		python.exe -B startmapper.py raw
		goto :finished
	)
)
rem If we're here, Python wasn't found in the path.
echo "Error: Unable to locate Python!"
echo "This script requires that either PyPy or Python be installed and in the path."
pause
:finished
rem Reset the working directory to it's previous value, before this batch script was run.
popd
