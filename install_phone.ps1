# RoadMesh Phone Installer
$ADB = "C:\src\android-sdk\platform-tools\adb.exe"
$APK = "c:\hackliv\RoadMesh\roadmesh-app\build\app\outputs\flutter-apk\app-debug.apk"

Write-Host "Checking Android device connection..."

while ($true) {
    $devices = & $ADB devices
    $deviceLine = $devices | Where-Object { $_ -match "\b(device|unauthorized|authorizing)\b" } | Select-Object -First 1

    if (-not $deviceLine) {
        Write-Host "No device found. Please connect your phone via USB cable..."
        Start-Sleep -Seconds 2
        continue
    }

    $parts = $deviceLine -split "\s+"
    $deviceId = $parts[0]
    $state = $parts[1]

    if ($state -eq "unauthorized" -or $state -eq "authorizing") {
        Write-Host "Device $deviceId is $state. Please UNLOCK phone and tap ALLOW on USB debugging prompt!"
        Start-Sleep -Seconds 2
        continue
    }

    if ($state -eq "device") {
        Write-Host "Phone authorized: $deviceId"
        break
    }
}

Write-Host "Configuring port forwarding..."
& $ADB -s $deviceId reverse tcp:3000 tcp:3000

Write-Host "Installing APK onto phone..."
& $ADB -s $deviceId install -r $APK

Write-Host "Launching RoadMesh app..."
& $ADB -s $deviceId shell am start -n com.example.roadmesh_app/.MainActivity

Write-Host "RoadMesh is now running on your phone!"
