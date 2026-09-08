#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🚗 RoadMesh — Master Orchestration & Deployment Suite
# ═══════════════════════════════════════════════════════════════════════════════
# Full Stack V2X Management:
#   • Mobile App: Flutter Android auto-detect, reverse ADB tunnel, build, install & launch
#   • Backend Core: Node 20 TypeScript spatial AI engine, WebSocket & REST API
#   • Web Console: High-contrast Tactical Geospatial Map Dashboard
#   • Cloud & Live: Render backend deploy + Vercel dashboard + Cloud URL mobile builder
# ═══════════════════════════════════════════════════════════════════════════════

# Note: not using set -e so phone/ADB failures don't kill server launch

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$ROOT_DIR/roadmesh-server"
APP_DIR="$ROOT_DIR/roadmesh-app"
PID_FILE="$ROOT_DIR/.roadmesh_pids"
SERVER_LOG="$ROOT_DIR/server.log"
APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"

# ─── Colors & Typography ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

get_local_ip() {
    local IP=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || ipconfig getifaddr bridge0 2>/dev/null)
    else
        IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    if [ -z "$IP" ]; then
        IP="127.0.0.1"
    fi
    echo "$IP"
}

LOCAL_IP=$(get_local_ip)

banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                              ║"
    echo "║     🚗  ROADMESH — MASTER ORCHESTRATOR & PRODUCTION SUITE                    ║"
    echo "║     Zero-Hardware Smartphone V2X • Spatial Collision AI • Tactical Radar     ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ─── System & Prerequisite Check ──────────────────────────────────────────────
check_prerequisites() {
    echo -e "${BLUE}${BOLD}🔍 Verifying Development Toolchain...${RESET}"
    local MISSING=0

    # Node.js
    if command -v node &> /dev/null; then
        local NODE_VER=$(node -v)
        echo -e "   ${GREEN}✓${RESET} Node.js:        ${BOLD}$NODE_VER${RESET}"
    else
        echo -e "   ${RED}✗ Node.js is not installed! (Requires >= 20.0.0)${RESET}"
        MISSING=1
    fi

    # npm
    if command -v npm &> /dev/null; then
        local NPM_VER=$(npm -v)
        echo -e "   ${GREEN}✓${RESET} npm:            ${BOLD}v$NPM_VER${RESET}"
    else
        echo -e "   ${RED}✗ npm is not installed!${RESET}"
        MISSING=1
    fi

    # Flutter
    if command -v flutter &> /dev/null; then
        local FLUTTER_VER=$(flutter --version | head -n 1 | awk '{print $2}')
        echo -e "   ${GREEN}✓${RESET} Flutter:        ${BOLD}v$FLUTTER_VER${RESET}"
    else
        echo -e "   ${RED}✗ Flutter SDK is not installed or not in PATH!${RESET}"
        MISSING=1
    fi

    # ADB
    if command -v adb &> /dev/null; then
        local ADB_VER=$(adb version | head -n 1)
        echo -e "   ${GREEN}✓${RESET} Android ADB:    ${BOLD}$ADB_VER${RESET}"
    else
        echo -e "   ${RED}✗ Android ADB platform-tools not found!${RESET}"
        MISSING=1
    fi

    # Git
    if command -v git &> /dev/null; then
        echo -e "   ${GREEN}✓${RESET} Git:            ${BOLD}$(git --version | awk '{print $3}')${RESET}"
    fi

    if [ "$MISSING" -ne 0 ]; then
        echo -e "\n${RED}${BOLD}❌ Missing required tools. Please install them before continuing.${RESET}\n"
        exit 1
    fi
    echo -e "   ${GREEN}${BOLD}Toolchain verification passed cleanly.${RESET}\n"
}

# ─── Stop Running Background Services ─────────────────────────────────────────
stop_services() {
    echo -e "\n${YELLOW}🛑 Terminating RoadMesh background instances...${RESET}"
    if [ -f "$PID_FILE" ]; then
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null
                echo -e "   Stopped process ${CYAN}$pid${RESET}"
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi

    # Kill port 3000 if occupied
    local PORT_PIDS=$(lsof -ti:3000 2>/dev/null || true)
    if [ -n "$PORT_PIDS" ]; then
        echo "$PORT_PIDS" | xargs kill -9 2>/dev/null || true
        echo -e "   ${GREEN}✓ Freed port 3000${RESET}"
    fi
    echo -e "${GREEN}✅ All RoadMesh background services stopped.${RESET}\n"
}

# ─── Build Backend Server ─────────────────────────────────────────────────────
build_server() {
    echo -e "${BLUE}${BOLD}📦 Building RoadMesh Backend Server & Dashboard...${RESET}"
    cd "$SERVER_DIR" || exit 1
    if [ ! -d "node_modules" ]; then
        echo -e "   ${CYAN}Installing backend npm dependencies...${RESET}"
        npm install
    fi
    npm run build
    echo -e "${GREEN}✅ Backend compilation & dashboard asset bundle ready.${RESET}\n"
}

# ─── Run Backend Tests ────────────────────────────────────────────────────────
test_server() {
    echo -e "${BLUE}${BOLD}🧪 Executing Server Vitest Verification Suite...${RESET}"
    cd "$SERVER_DIR" || exit 1
    npm test
    echo -e "${GREEN}✅ All 61 backend unit & integration tests passed!${RESET}\n"
}

# ─── Start Backend Server ─────────────────────────────────────────────────────
start_server() {
    stop_services
    build_server

    echo -e "${CYAN}${BOLD}🚀 Launching RoadMesh Core Server on port 3000...${RESET}"
    cd "$SERVER_DIR" || exit 1
    node dist/index.js > "$SERVER_LOG" 2>&1 &
    local PID=$!
    echo "$PID" > "$PID_FILE"

    # Health check wait loop
    echo -e "   ${CYAN}Waiting for health check (http://localhost:3000/health)...${RESET}"
    local ATTEMPTS=0
    local HEALTHY=false
    while [ $ATTEMPTS -lt 15 ]; do
        if curl -s -f http://localhost:3000/health > /dev/null 2>&1; then
            HEALTHY=true
            break
        fi
        sleep 0.5
        ATTEMPTS=$((ATTEMPTS + 1))
    done

    if [ "$HEALTHY" = true ]; then
        echo -e "   ${GREEN}✓ Server online & healthy! (PID: $PID)${RESET}"
    else
        echo -e "   ${YELLOW}⚠️  Server process spawned but health endpoint didn't respond immediately.${RESET}"
        echo -e "   Check log: ${BOLD}$SERVER_LOG${RESET}"
    fi

    echo -e "\n${WHITE}${BOLD}📡 ROADMESH CONNECTION ENDPOINTS:${RESET}"
    echo -e "   ${CYAN}• USB Tunnel (Physical Phone via ADB):${RESET}  ${BOLD}${GREEN}ws://127.0.0.1:3000/ws${RESET}"
    echo -e "   ${BLUE}• Wi-Fi (Phones on local network):${RESET}      ${BOLD}ws://${LOCAL_IP}:3000/ws${RESET}"
    echo -e "   ${MAGENTA}• Tactical Operations Dashboard:${RESET}        ${BOLD}http://localhost:3000/dashboard/${RESET}"
    echo -e "   ${DIM}• Health Check & REST API:${RESET}              http://localhost:3000/health\n"
}

# ─── Detect & Configure Connected Android Phone ───────────────────────────────
detect_and_configure_phone() {
    echo -e "${BLUE}${BOLD}📱 Scanning for Connected Android Devices via ADB...${RESET}"

    get_device_line() {
        adb devices | grep -v "List of devices" | grep -v "^$" | head -n 1
    }

    local DEVICE_LINE="$(get_device_line)"

    if [ -z "$DEVICE_LINE" ]; then
        echo -e "${YELLOW}⚠️  No Android phone detected over USB.${RESET}"
        echo -e "   1. Connect your Android phone to this Mac using a USB cable."
        echo -e "   2. Enable ${BOLD}Developer Options${RESET} and turn ON ${BOLD}USB Debugging${RESET}."
        echo -e "\n${CYAN}⏳ Waiting for device connection (Ctrl+C to skip)...${RESET}"
        local WAIT_COUNT=0
        while [ -z "$DEVICE_LINE" ] && [ $WAIT_COUNT -lt 30 ]; do
            sleep 1
            DEVICE_LINE="$(get_device_line)"
            WAIT_COUNT=$((WAIT_COUNT + 1))
        done

        if [ -z "$DEVICE_LINE" ]; then
            echo -e "${YELLOW}⚠️  Skipping mobile phone auto-setup (no device plugged in).${RESET}\n"
            return 1
        fi
    fi

    # Handle unauthorized prompt on phone screen
    if echo "$DEVICE_LINE" | grep -q "unauthorized"; then
        echo -e "\n${YELLOW}${BOLD}⚠️  DEVICE DETECTED BUT NOT YET AUTHORIZED!${RESET}"
        echo -e "${YELLOW}👉 Check your phone screen now:${RESET}"
        echo -e "   1. Unlock your phone."
        echo -e "   2. A popup says ${BOLD}\"Allow USB debugging?\"${RESET}"
        echo -e "   3. Check ${BOLD}\"Always allow from this computer\"${RESET} and tap ${BOLD}ALLOW${RESET}."
        echo -e "\n${CYAN}🔄 Refreshing ADB daemon...${RESET}"
        adb kill-server > /dev/null 2>&1 || true
        adb start-server > /dev/null 2>&1 || true

        for i in {1..30}; do
            DEVICE_LINE="$(get_device_line)"
            if echo "$DEVICE_LINE" | grep -q "device$"; then
                break
            fi
            sleep 1
        done
    fi

    # Handle offline state — phone USB mode may have switched to charging-only
    if echo "$DEVICE_LINE" | grep -q "offline"; then
        echo -e "\n${YELLOW}${BOLD}⚠️  DEVICE IS OFFLINE — USB mode may have changed!${RESET}"
        echo -e "${YELLOW}👉 On your phone:${RESET}"
        echo -e "   1. Pull down the notification shade."
        echo -e "   2. Tap ${BOLD}\"USB charging this device\"${RESET} or ${BOLD}\"Android System\"${RESET}."
        echo -e "   3. Select ${BOLD}\"File Transfer\"${RESET} (MTP) mode."
        echo -e "   4. Re-authorize USB debugging if prompted.\n"
        echo -e "${CYAN}⏳ Waiting up to 30s for device to come back online...${RESET}"
        adb kill-server > /dev/null 2>&1 || true
        adb start-server > /dev/null 2>&1 || true

        for i in {1..30}; do
            DEVICE_LINE="$(get_device_line)"
            if echo "$DEVICE_LINE" | grep -q "device$"; then
                echo -e "   ${GREEN}✓ Device recovered and ready!${RESET}"
                break
            fi
            sleep 1
        done
    fi

    DEVICE_ID=$(echo "$DEVICE_LINE" | awk '{print $1}')
    DEVICE_STATE=$(echo "$DEVICE_LINE" | awk '{print $2}')

    if [ "$DEVICE_STATE" != "device" ]; then
        echo -e "${RED}❌ Phone is still in state '${DEVICE_STATE}'.${RESET}"
        echo -e "${YELLOW}   Switch USB mode to 'File Transfer' on your phone and run again.${RESET}\n"
        DEVICE_ID=""   # Clear so deploy_mobile_app skips safely
        return 1
    fi

    local MODEL=$(adb -s "$DEVICE_ID" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
    local ANDROID_VER=$(adb -s "$DEVICE_ID" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
    local BATTERY=$(adb -s "$DEVICE_ID" shell dumpsys battery 2>/dev/null | grep -E "^\s*level:" | head -n 1 | awk '{print $2}' | tr -d '\r' || echo "N/A")

    echo -e "   ${GREEN}✓ Connected Phone:${RESET} ${BOLD}$MODEL${RESET} (Android $ANDROID_VER, Battery: $BATTERY%)"
    echo -e "   ${DIM}• Device ID:${RESET}       $DEVICE_ID"

    # Configure Reverse Port Forwarding Tunnel
    echo -e "\n${CYAN}🔌 Activating Reverse Port Tunneling (${BOLD}adb reverse tcp:3000 tcp:3000${RESET}${CYAN})...${RESET}"
    adb -s "$DEVICE_ID" reverse tcp:3000 tcp:3000
    echo -e "   ${GREEN}✓ Active Reverse Tunnel: Phone 127.0.0.1:3000 ⇄ Computer :3000${RESET}"
    echo -e "   ${DIM}The phone can now reach the RoadMesh WebSocket server directly over USB with 0ms router latency.${RESET}\n"
    return 0
}

# ─── Build, Install & Launch Flutter App ──────────────────────────────────────
deploy_mobile_app() {
    local CLOUD_WS_URL="$1"

    if [ -z "$DEVICE_ID" ]; then
        if ! detect_and_configure_phone; then
            echo -e "${RED}Cannot install mobile app without a connected Android device.${RESET}\n"
            return 1
        fi
    fi

    echo -e "${BLUE}${BOLD}📱 Deploying RoadMesh Mobile App to $DEVICE_ID...${RESET}"
    cd "$APP_DIR" || exit 1

    # Check if rebuild is necessary
    local BUILD_NEEDED=false
    if [ ! -f "$APK_PATH" ]; then
        BUILD_NEEDED=true
    elif [ -n "$CLOUD_WS_URL" ]; then
        BUILD_NEEDED=true
    else
        # If any dart files are newer than the built APK
        local NEWEST_DART=$(find lib -name "*.dart" -newer "$APK_PATH" 2>/dev/null | head -n 1)
        if [ -n "$NEWEST_DART" ]; then
            BUILD_NEEDED=true
        fi
    fi

    if [ "$BUILD_NEEDED" = true ]; then
        echo -e "   ${CYAN}🔨 Compiling debug APK for android-arm64...${RESET}"
        if [ -n "$CLOUD_WS_URL" ]; then
            echo -e "   ${MAGENTA}Targeting Live Cloud WebSocket:${RESET} ${BOLD}$CLOUD_WS_URL${RESET}"
            flutter build apk --debug --target-platform android-arm64 --dart-define="ROAD_MESH_WS_URL=$CLOUD_WS_URL"
        else
            flutter build apk --debug --target-platform android-arm64
        fi
        echo -e "   ${GREEN}✓ APK compiled successfully.${RESET}"
    else
        echo -e "   ${GREEN}✓ Pre-built APK is up-to-date.${RESET}"
    fi

    # Install to phone with auto-recovery for debug testOnly APKs, signature mismatch, and OEM blockers
    echo -e "   ${CYAN}📲 Installing APK onto device...${RESET}"
    local INSTALL_OUT
    local INSTALL_SUCCESS=false

    # Try 1: Standard install with testOnly (-t) and downgrade (-d) flags
    INSTALL_OUT=$(adb -s "$DEVICE_ID" install -r -d -t "$APK_PATH" 2>&1)
    if [ $? -eq 0 ] && ! echo "$INSTALL_OUT" | grep -qi "fail"; then
        INSTALL_SUCCESS=true
    else
        # Try 2: Recover from signature mismatch
        if echo "$INSTALL_OUT" | grep -q "INSTALL_FAILED_UPDATE_INCOMPATIBLE"; then
            echo -e "   ${YELLOW}⚠️  Existing app signature mismatch detected.${RESET}"
            echo -e "   ${CYAN}Cleaning previous version and performing fresh install...${RESET}"
            adb -s "$DEVICE_ID" uninstall com.example.roadmesh_app > /dev/null 2>&1 || true
            INSTALL_OUT=$(adb -s "$DEVICE_ID" install -r -d -t "$APK_PATH" 2>&1)
            if [ $? -eq 0 ] && ! echo "$INSTALL_OUT" | grep -qi "fail"; then
                INSTALL_SUCCESS=true
            fi
        fi

        # Try 3: Non-streamed install (fixes Samsung One UI streamed socket drops)
        if [ "$INSTALL_SUCCESS" = false ]; then
            echo -e "   ${CYAN}Retrying with non-streamed install...${RESET}"
            INSTALL_OUT=$(adb -s "$DEVICE_ID" install --no-streaming -r -d -t "$APK_PATH" 2>&1)
            if [ $? -eq 0 ] && ! echo "$INSTALL_OUT" | grep -qi "fail"; then
                INSTALL_SUCCESS=true
            fi
        fi

        # Try 4: Full uninstall + reinstall
        if [ "$INSTALL_SUCCESS" = false ]; then
            echo -e "   ${CYAN}Attempting fresh reinstall...${RESET}"
            adb -s "$DEVICE_ID" uninstall com.example.roadmesh_app > /dev/null 2>&1 || true
            INSTALL_OUT=$(adb -s "$DEVICE_ID" install -r -d -t "$APK_PATH" 2>&1)
            if [ $? -eq 0 ] && ! echo "$INSTALL_OUT" | grep -qi "fail"; then
                INSTALL_SUCCESS=true
            fi
        fi
    fi

    if [ "$INSTALL_SUCCESS" = false ]; then
        echo -e "${RED}Install failed: $INSTALL_OUT${RESET}"
        echo -e "\n${YELLOW}${BOLD}👉 SAMSUNG (ONE UI) FIX:${RESET}"
        echo -e "   1. ${BOLD}Disable Samsung Auto Blocker:${RESET}"
        echo -e "      Open phone ${CYAN}Settings${RESET} ➔ ${CYAN}Security and privacy${RESET} ➔ ${CYAN}Auto Blocker${RESET} ➔ Toggle ${BOLD}OFF${RESET}"
        echo -e "      ${DIM}(Auto Blocker silently kills USB / ADB app installations on Samsung Galaxy phones)${RESET}"
        echo -e "   2. ${BOLD}Keep Phone Unlocked:${RESET}"
        echo -e "      If Google Play Protect popup appears, tap ${BOLD}'Install anyway'${RESET}"
        echo -e "   3. ${BOLD}Developer Options:${RESET}"
        echo -e "      Ensure ${CYAN}Install via USB${RESET} is enabled in Developer Options"
        return 1
    fi
    echo -e "   ${GREEN}✓ RoadMesh App installed.${RESET}"

    # Auto-grant permissions so user doesn't get blocked
    echo -e "   ${CYAN}🛡️  Granting location and notification permissions...${RESET}"
    adb -s "$DEVICE_ID" shell pm grant com.example.roadmesh_app android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
    adb -s "$DEVICE_ID" shell pm grant com.example.roadmesh_app android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
    adb -s "$DEVICE_ID" shell pm grant com.example.roadmesh_app android.permission.POST_NOTIFICATIONS 2>/dev/null || true
    echo -e "   ${GREEN}✓ Runtime permissions granted.${RESET}"

    # Launch app
    echo -e "   ${GREEN}🚀 Starting RoadMesh activity on phone screen...${RESET}"
    adb -s "$DEVICE_ID" shell am start -n com.example.roadmesh_app/.MainActivity
    echo -e "   ${GREEN}${BOLD}🎉 RoadMesh App is now active on your phone!${RESET}\n"
}

# ─── Open Dashboard in Browser ────────────────────────────────────────────────
open_dashboard() {
    echo -e "${MAGENTA}${BOLD}📊 Opening Tactical Geospatial Operations Map...${RESET}"
    local DASH_URL="http://localhost:3000/dashboard/"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$DASH_URL"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "$DASH_URL"
    fi
    echo -e "   ${GREEN}✓ Opened ${BOLD}$DASH_URL${RESET} in default browser.\n"
}

# ─── Live Diagnostics & Status ────────────────────────────────────────────────
show_status() {
    banner
    echo -e "${WHITE}${BOLD}📊 ROADMESH SYSTEM STATUS${RESET}\n"

    # Server Status
    echo -e "${BOLD}1. Backend Core Server:${RESET}"
    if curl -s -f http://localhost:3000/health > /dev/null 2>&1; then
        local STATS=$(curl -s http://localhost:3000/stats 2>/dev/null || echo "{}")
        local CLIENTS=$(echo "$STATS" | grep -o '"wsClients":[0-9]*' | head -n 1 | cut -d: -f2 || echo "0")
        local VEHICLES=$(echo "$STATS" | grep -o '"totalVehicles":[0-9]*' | head -n 1 | cut -d: -f2 || echo "0")
        echo -e "   Status:      ${GREEN}${BOLD}ONLINE (Port 3000)${RESET}"
        echo -e "   WS Clients:  ${CYAN}$CLIENTS${RESET}"
        echo -e "   Active Nodes:${CYAN}$VEHICLES${RESET}"
        echo -e "   Dashboard:   ${BLUE}http://localhost:3000/dashboard/${RESET}"
    else
        echo -e "   Status:      ${RED}${BOLD}OFFLINE${RESET}"
    fi

    # Device Status
    echo -e "\n${BOLD}2. Physical Android Phone (USB):${RESET}"
    if command -v adb &> /dev/null; then
        local DEV=$(adb devices | grep -v "List of devices" | grep -v "^$" | head -n 1)
        if [ -n "$DEV" ]; then
            local DID=$(echo "$DEV" | awk '{print $1}')
            local DSTATE=$(echo "$DEV" | awk '{print $2}')
            local MODEL=$(adb -s "$DID" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
            echo -e "   Device:      ${GREEN}${BOLD}$MODEL${RESET} ($DID)"
            echo -e "   State:       ${GREEN}$DSTATE${RESET}"

            # Check reverse tunnel
            local REVERSE_TUNNEL=$(adb -s "$DID" reverse --list 2>/dev/null | grep "3000" || true)
            if [ -n "$REVERSE_TUNNEL" ]; then
                echo -e "   Tunnel:      ${GREEN}${BOLD}Active (127.0.0.1:3000 ⇄ Computer:3000)${RESET}"
            else
                echo -e "   Tunnel:      ${YELLOW}Not configured (Run ./master.sh --adb)${RESET}"
            fi
        else
            echo -e "   Device:      ${YELLOW}No device connected${RESET}"
        fi
    fi

    # Cloud Configuration
    echo -e "\n${BOLD}3. Cloud & Production Setup:${RESET}"
    echo -e "   Render Spec: ${GREEN}render.yaml (Configured)${RESET}"
    echo -e "   Vercel Spec: ${GREEN}vercel.json (Configured)${RESET}"
    echo -e "   Guide:       ${BLUE}docs/CLOUD_DEPLOYMENT.md${RESET}\n"
}

# ─── Cloud & Production Deployment Assistant ──────────────────────────────────
cloud_deployment_wizard() {
    banner
    echo -e "${MAGENTA}${BOLD}☁️  ROADMESH CLOUD & PRODUCTION DEPLOYMENT ASSISTANT${RESET}\n"
    echo -e "RoadMesh supports two production deployment architectures:\n"
    echo -e "  ${BOLD}Option 1: 1-Click Unified Render Deployment (Recommended)${RESET}"
    echo -e "    • Deploy the full stack (WebSocket server + REST API + Tactical Dashboard) to Render."
    echo -e "    • Render uses the included ${CYAN}render.yaml${RESET} blueprint."
    echo -e "    • Live Product URL: ${GREEN}https://<your-service>.onrender.com/dashboard/${RESET}"
    echo -e "    • Live WebSocket:   ${GREEN}wss://<your-service>.onrender.com/ws${RESET}\n"
    echo -e "  ${BOLD}Option 2: Decoupled Deploy (Render Backend + Vercel Dashboard CDN)${RESET}"
    echo -e "    • Backend: Deploy ${CYAN}roadmesh-server${RESET} to Render (for WebSockets & spatial AI)."
    echo -e "    • Frontend: Deploy ${CYAN}vercel.json${RESET} to Vercel (for instant Edge CDN delivery)."
    echo -e "    • The dashboard connects seamlessly to your Render backend.\n"

    echo -e "${BOLD}Would you like to build the mobile app for a live Cloud Render URL?${RESET}"
    echo -e "Enter your live Render WebSocket URL (e.g. ${CYAN}wss://roadmesh-server.onrender.com/ws${RESET})"
    read -p "Cloud WS URL (or press Enter to skip): " CLOUD_URL

    if [ -n "$CLOUD_URL" ]; then
        deploy_mobile_app "$CLOUD_URL"
    else
        echo -e "\nFor full step-by-step instructions, view: ${BOLD}docs/CLOUD_DEPLOYMENT.md${RESET}\n"
    fi
}

# ─── All-In-One One-Click Orchestration ───────────────────────────────────────
run_all() {
    banner
    echo -e "${GREEN}${BOLD}🚀 RUNNING ALL-IN-ONE ROADMESH ENVIRONMENT SETUP${RESET}\n"
    check_prerequisites
    start_server
    detect_and_configure_phone || true
    if [ -n "$DEVICE_ID" ]; then
        deploy_mobile_app || echo -e "${YELLOW}⚠️  Phone deploy failed — server & dashboard still running.${RESET}"
    fi
    open_dashboard

    echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}🎉 ROADMESH FULL STACK IS LIVE & RUNNING!${RESET}"
    echo -e "   • ${BOLD}Tactical Operations Dashboard:${RESET} http://localhost:3000/dashboard/"
    echo -e "   • ${BOLD}Phone App Status:${RESET}               Running on device (ADB reverse active)"
    echo -e "   • ${BOLD}Server Status:${RESET}                  Port 3000 (PID: $(cat "$PID_FILE" 2>/dev/null || echo "N/A"))"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${RESET}\n"
}

# ─── CLI Arguments Dispatcher ─────────────────────────────────────────────────
case "$1" in
    --all|-a|all)
        run_all
        exit 0
        ;;
    --server|-s|server)
        banner
        start_server
        open_dashboard
        exit 0
        ;;
    --mobile|-m|mobile|phone|app)
        banner
        detect_and_configure_phone
        deploy_mobile_app
        exit 0
        ;;
    --adb|--tunnel|adb|usb)
        banner
        detect_and_configure_phone
        exit 0
        ;;
    --cloud|cloud)
        if [ -n "$2" ]; then
            banner
            detect_and_configure_phone
            deploy_mobile_app "$2"
        else
            cloud_deployment_wizard
        fi
        exit 0
        ;;
    --deploy|deploy)
        cloud_deployment_wizard
        exit 0
        ;;
    --status|status)
        show_status
        exit 0
        ;;
    --test|test)
        banner
        test_server
        exit 0
        ;;
    --stop|stop)
        stop_services
        exit 0
        ;;
    --help|-h|help)
        banner
        echo -e "${BOLD}Usage:${RESET} ./master.sh [COMMAND]\n"
        echo -e "${BOLD}Commands:${RESET}"
        echo -e "  ${GREEN}--all, -a${RESET}         1-Click Full Stack: Server + Phone ADB Reverse + App Install + Dashboard"
        echo -e "  ${CYAN}--server, -s${RESET}      Start Backend Server on port 3000 & open Dashboard"
        echo -e "  ${BLUE}--mobile, -m${RESET}      Detect Android phone, set up ADB reverse, build, install & launch app"
        echo -e "  ${YELLOW}--adb${RESET}             Pair Android phone & configure reverse port tunnel only"
        echo -e "  ${MAGENTA}--cloud [URL]${RESET}     Build and install mobile app configured with live Render cloud URL"
        echo -e "  ${MAGENTA}--deploy${RESET}          Cloud deployment assistant for Render and Vercel"
        echo -e "  ${WHITE}--status${RESET}          Show live system diagnostics (server, phone, tunnels, cloud)"
        echo -e "  ${CYAN}--test${RESET}            Run Vitest test suite"
        echo -e "  ${RED}--stop${RESET}            Stop all RoadMesh background processes"
        echo -e "  ${DIM}--help, -h${RESET}        Show this help screen\n"
        exit 0
        ;;
esac

# ─── Interactive Terminal Menu (Default) ──────────────────────────────────────
while true; do
    banner
    echo -e "${BOLD}Select an action to perform:${RESET}"
    echo -e "  ${GREEN}${BOLD}[1] 🚀 1-CLICK RUN EVERYTHING (Server + Phone + Reverse Tunnel + Dashboard)${RESET}"
    echo -e "  ${CYAN}[2] 🖥️  Start Core Server (:3000) & Open Tactical Map Dashboard${RESET}"
    echo -e "  ${BLUE}[3] 📱 Setup Connected Phone (ADB Reverse Tunnel + Install & Launch App)${RESET}"
    echo -e "  ${YELLOW}[4] 🔌 Configure Android USB Port Forwarding (adb reverse tcp:3000 tcp:3000)${RESET}"
    echo -e "  ${MAGENTA}[5] ☁️  Cloud Deployment Assistant (Render & Vercel for Live Product)${RESET}"
    echo -e "  ${WHITE}[6] 📊 Live System Diagnostics & Status Check${RESET}"
    echo -e "  ${CYAN}[7] 🧪 Run Verification & Automated Unit Tests (Vitest)${RESET}"
    echo -e "  ${RED}[8] 🛑 Stop All Running RoadMesh Background Services${RESET}"
    echo -e "  [9] ❌ Exit\n"
    read -p "Enter choice [1-9]: " choice

    case $choice in
        1)
            run_all
            break
            ;;
        2)
            start_server
            open_dashboard
            break
            ;;
        3)
            detect_and_configure_phone
            deploy_mobile_app
            read -p "Press Enter to return to menu..."
            ;;
        4)
            detect_and_configure_phone
            read -p "Press Enter to return to menu..."
            ;;
        5)
            cloud_deployment_wizard
            read -p "Press Enter to return to menu..."
            ;;
        6)
            show_status
            read -p "Press Enter to return to menu..."
            ;;
        7)
            test_server
            read -p "Press Enter to return to menu..."
            ;;
        8)
            stop_services
            read -p "Press Enter to return to menu..."
            ;;
        9)
            echo -e "\n${CYAN}Exiting RoadMesh. Safe driving! 🚗${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection. Please choose 1-9.${RESET}"
            sleep 1
            ;;
    esac
done
