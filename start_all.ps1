# RoadMesh Master Launcher (Windows)
$ROOT = "c:\hackliv\RoadMesh"
$SERVER_DIR = "$ROOT\roadmesh-server"
$TOOLS_DIR = "$ROOT\tools"
$APP_DIR = "$ROOT\roadmesh-app"
$ADB = "C:\src\android-sdk\platform-tools\adb.exe"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "       ROADMESH - COOPERATIVE V2X PLATFORM MASTER LAUNCHER                " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check Core Backend Server (Port 3000)
Write-Host "[1/5] Checking RoadMesh Core Backend Server on Port 3000..." -ForegroundColor Yellow
$port3000 = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue

if (-not $port3000) {
    Write-Host "   Starting Core Backend Server..." -ForegroundColor Gray
    Start-Process -FilePath "node" -ArgumentList "dist/index.js" -WorkingDirectory $SERVER_DIR -WindowStyle Hidden
    Start-Sleep -Seconds 2
    Write-Host "   Core Backend Server running on http://localhost:3000" -ForegroundColor Green
} else {
    Write-Host "   Core Backend Server is already active on http://localhost:3000" -ForegroundColor Green
}

# 2. Check Traffic Simulator (Port 3001)
Write-Host "[2/5] Checking Indian Traffic Simulator on Port 3001..." -ForegroundColor Yellow
$port3001 = Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue

if (-not $port3001) {
    Write-Host "   Starting Traffic Simulator..." -ForegroundColor Gray
    Start-Process -FilePath "node" -ArgumentList "server.js" -WorkingDirectory $TOOLS_DIR -WindowStyle Hidden
    Start-Sleep -Seconds 2
    Write-Host "   Simulator running on http://localhost:3001" -ForegroundColor Green
} else {
    Write-Host "   Simulator is already active on http://localhost:3001" -ForegroundColor Green
}

# 3. Check Web Cockpit (Port 8080)
Write-Host "[3/5] Checking Mobile Web App on Port 8080..." -ForegroundColor Yellow
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

# 4. Configure ADB Port Forwarding for Connected Phone
Write-Host "[4/5] Checking Connected Android Phone via USB..." -ForegroundColor Yellow
if (Test-Path $ADB) {
    $devices = & $ADB devices
    $deviceLine = $devices | Where-Object { $_ -match "\bdevice\b" } | Select-Object -First 1

    if ($deviceLine) {
        $deviceId = ($deviceLine -split "\s+")[0]
        Write-Host "   Found authorized phone: $deviceId" -ForegroundColor Cyan
        Write-Host "   Configuring port forwarding (adb reverse tcp:3000 tcp:3000)..." -ForegroundColor Gray
        & $ADB -s $deviceId reverse tcp:3000 tcp:3000
        
        Write-Host "[5/5] Launching RoadMesh Navigation App on phone..." -ForegroundColor Yellow
        & $ADB -s $deviceId shell am start -n com.example.roadmesh_app/.MainActivity | Out-Null
        Write-Host "   RoadMesh Cockpit launched on phone!" -ForegroundColor Green
    } else {
        Write-Host "   No phone detected over USB right now. You can plug it in anytime and run run_phone.bat" -ForegroundColor Gray
    }
} else {
    Write-Host "   ADB not found at $ADB" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "                    ALL SYSTEMS OPERATIONAL!                              " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Core V2X Backend Server:    http://localhost:3000" -ForegroundColor White
Write-Host "  Traffic Control Dashboard:  http://localhost:3001" -ForegroundColor White
Write-Host "  Web Navigation Cockpit:     http://localhost:8080" -ForegroundColor White
Write-Host "  Phone Wi-Fi Access:         http://10.210.147.135:8080" -ForegroundColor White
Write-Host ""
Write-Host "Opening Traffic Control Dashboard in browser..." -ForegroundColor Cyan
Start-Process "http://localhost:3001"
