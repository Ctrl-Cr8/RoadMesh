# RoadMesh Master Launcher (Windows)
$ROOT = "c:\hackliv\RoadMesh"
$SERVER_DIR = "$ROOT\roadmesh-server"
$APP_DIR = "$ROOT\roadmesh-app"
$ADB = "C:\src\android-sdk\platform-tools\adb.exe"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "       ROADMESH - COOPERATIVE V2X PLATFORM MASTER LAUNCHER                " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Build and Check Core Backend Server (Port 3000)
Write-Host "[1/4] Checking RoadMesh Core Backend Server & Operations Dashboard (Port 3000)..." -ForegroundColor Yellow
$port3000 = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue

if (-not $port3000) {
    Write-Host "   Compiling & Starting Core Backend Server..." -ForegroundColor Gray
    Start-Process -FilePath "npm" -ArgumentList "run build" -WorkingDirectory $SERVER_DIR -Wait -WindowStyle Hidden
    Start-Process -FilePath "node" -ArgumentList "dist/index.js" -WorkingDirectory $SERVER_DIR -WindowStyle Hidden
    Start-Sleep -Seconds 2
    Write-Host "   Core Backend & Operations Dashboard running on http://localhost:3000" -ForegroundColor Green
} else {
    Write-Host "   Core Backend Server & Operations Dashboard active on http://localhost:3000" -ForegroundColor Green
}

# 2. Check Web Cockpit (Port 8080)
Write-Host "[2/4] Checking Mobile Web App Cockpit on Port 8080..." -ForegroundColor Yellow
$port8080 = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue

if (-not $port8080) {
    Write-Host "   Starting Web App Host..." -ForegroundColor Gray
    $env:NODE_PATH = "$SERVER_DIR\node_modules"
    Start-Process -FilePath "node" -ArgumentList "server.js" -WorkingDirectory $APP_DIR -WindowStyle Hidden
    Start-Sleep -Seconds 2
    Write-Host "   Web Cockpit running on http://localhost:8080" -ForegroundColor Green
} else {
    Write-Host "   Web Cockpit is already active on http://localhost:8080" -ForegroundColor Green
}

# 3. Configure ADB Port Forwarding for Connected Phone
Write-Host "[3/4] Checking Connected Android Phone via USB..." -ForegroundColor Yellow
if (Test-Path $ADB) {
    $devices = & $ADB devices
    $deviceLine = $devices | Where-Object { $_ -match "\bdevice\b" } | Select-Object -First 1

    if ($deviceLine) {
        $deviceId = ($deviceLine -split "\s+")[0]
        Write-Host "   Found authorized phone: $deviceId" -ForegroundColor Cyan
        Write-Host "   Configuring port forwarding (adb reverse tcp:3000 tcp:3000)..." -ForegroundColor Gray
        & $ADB -s $deviceId reverse tcp:3000 tcp:3000
        
        Write-Host "[4/4] Launching RoadMesh Navigation App on phone..." -ForegroundColor Yellow
        & $ADB -s $deviceId shell am start -n com.example.roadmesh_app/.MainActivity | Out-Null
        Write-Host "   RoadMesh Cockpit launched on phone!" -ForegroundColor Green
    } else {
        Write-Host "   No phone detected over USB right now. (Access via Wi-Fi: http://10.39.66.135:8080)" -ForegroundColor Gray
    }
} else {
    Write-Host "   ADB not found at $ADB" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "                    ALL SYSTEMS OPERATIONAL!                              " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Operations Console Dashboard:  http://localhost:3000/dashboard" -ForegroundColor White
Write-Host "  Core V2X WebSocket Stream:     ws://localhost:3000/ws" -ForegroundColor White
Write-Host "  Web Navigation Cockpit:        http://localhost:8080" -ForegroundColor White
Write-Host "  Phone Direct Wi-Fi Access:     http://10.39.66.135:8080" -ForegroundColor White
Write-Host ""
Write-Host "Opening Operations Dashboard and Web Cockpit in browser..." -ForegroundColor Cyan
Start-Process "http://localhost:3000/dashboard"
Start-Process "http://localhost:8080"
