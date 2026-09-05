@echo off
set "JAVA_HOME=C:\src\jdk-17"
set "ANDROID_HOME=C:\src\android-sdk"
set "PATH=C:\src\jdk-17\bin;C:\src\android-sdk\platform-tools;C:\src\flutter\bin;%PATH%"

echo ========================================================
echo   Launching RoadMesh on Connected Android Phone
echo ========================================================

powershell -ExecutionPolicy Bypass -File "%~dp0install_phone.ps1"
