@echo off

cls

rem Change the current working directory to the location of this batch script.
pushd "%~dp0"

luajit.exe update_checker.lua %*

rem Reset the working directory to it's previous value, before this batch script was run.
popd
