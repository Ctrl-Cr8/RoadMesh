@echo off
set "PATH=C:\src\flutter\bin;%PATH%"
cd /d "%~dp0roadmesh-app"

echo ========================================================
echo   Launching RoadMesh in Chrome Browser
echo ========================================================

flutter run -d chrome
