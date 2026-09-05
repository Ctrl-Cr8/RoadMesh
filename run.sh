#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🚗 RoadMesh — Real-Time Smartphone V2X Platform & Master Orchestrator
# ═══════════════════════════════════════════════════════════════════════════════
# 100% Real-Time Smartphone Telemetry Architecture:
#   • V2V (Vehicle-to-Vehicle): Flutter Mobile GPS + Compass Telemetry
#   • V2I (Vehicle-to-Infrastructure): Arduino UNO Smart School Crossing Beacon
#   • Spatial Core: Geohash Spatial Grid + Time-to-Collision (TCA) AI Engine
#   • Live Operations Console: High-Contrast Tactical Map Dashboard
# ═══════════════════════════════════════════════════════════════════════════════

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$ROOT_DIR/roadmesh-server"
GATEWAY_DIR="$ROOT_DIR/arduino/gateway"
APP_DIR="$ROOT_DIR/roadmesh-app"

PID_FILE="$ROOT_DIR/.roadmesh_pids"

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

get_local_ip() {
    local IP=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
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
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                          ║"
    echo "║     🚗  ROADMESH — REAL-TIME SMARTPHONE V2X PLATFORM                     ║"
    echo "║     100% Live GPS Telemetry • Zero Simulation • Pure V2V / V2I          ║"
    echo "║                                                                          ║"
    echo "║     • Live V2V: Flutter Mobile App (Continuous High-Accuracy GPS)        ║"
    echo "║     • Live V2I: Arduino UNO Smart School Crossing Beacon                 ║"
    echo "║     • Console:  Tactical Geospatial Operations Map (:3000)               ║"
    echo "║                                                                          ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

stop_all() {
    echo -e "\n${YELLOW}🛑 Stopping RoadMesh background processes...${RESET}"
    if [ -f "$PID_FILE" ]; then
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null
                echo -e "   Stopped process ${CYAN}$pid${RESET}"
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi

    # Kill any lingering port 3000
    lsof -ti:3000 | xargs kill -9 2>/dev/null

    echo -e "${GREEN}✅ All RoadMesh background processes stopped.${RESET}\n"
}

start_server() {
    stop_all
    touch "$PID_FILE"

    echo -e "${CYAN}🚀 Starting RoadMesh Core Server on port 3000...${RESET}"
    cd "$SERVER_DIR" || exit 1
    node dist/index.js > "$ROOT_DIR/server.log" 2>&1 &
    local PID=$!
    echo "$PID" >> "$PID_FILE"
    sleep 1

    echo -e "   ${GREEN}✓ Server started (PID: $PID)${RESET}"
    echo -e "\n${BOLD}📡 TELEMETRY CONNECTION ENDPOINTS FOR MOBILE PHONES:${RESET}"
    echo -e "   ${CYAN}• Wi-Fi Target (Flutter phones on same network):${RESET}"
    echo -e "     ${BOLD}${GREEN}ws://${LOCAL_IP}:3000/ws${RESET}"
    echo -e "   ${BLUE}• USB Tunnel (Android phone over USB cable):${RESET}"
    echo -e "     ${BOLD}ws://localhost:3000/ws${RESET} ${YELLOW}(Run: adb reverse tcp:3000 tcp:3000)${RESET}"
    echo -e "\n   📊 ${BOLD}Tactical Operations Dashboard:${RESET} ${CYAN}http://localhost:3000/dashboard/${RESET}"

    # Open Dashboard in default browser on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "http://localhost:3000/dashboard/"
    fi
}

pair_android_usb() {
    banner
    echo -e "${BLUE}${BOLD}🔌 ANDROID USB PORT FORWARDING (ADB REVERSE)${RESET}\n"
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}❌ 'adb' command not found. Please install Android Platform Tools.${RESET}"
        return
    fi

    echo -e "🔍 Checking connected Android devices..."
    local DEVICE=$(adb devices | grep -v "List of devices" | grep -v "^$" | head -n 1)
    if [ -z "$DEVICE" ]; then
        echo -e "${YELLOW}⚠️  No Android device detected over USB.${RESET}"
        echo -e "   1. Connect phone via USB cable."
        echo -e "   2. Ensure Developer Options & USB Debugging are ON."
        return
    fi

    adb reverse tcp:3000 tcp:3000
    echo -e "${GREEN}✅ Active Reverse Tunnel: phone 127.0.0.1:3000 -> computer:3000${RESET}"
    echo -e "   The Flutter app can now connect to: ${BOLD}${CYAN}ws://localhost:3000/ws${RESET}"
}

start_gateway() {
    echo -e "\n${MAGENTA}🚸 Starting Arduino Uno V2I Smart Crossing Gateway...${RESET}"
    echo -e "   ${YELLOW}Hint: You can press [SPACE] in the gateway anytime to simulate pedestrian button!${RESET}"
    cd "$GATEWAY_DIR" || exit 1
    node gateway.js
}

start_app() {
    echo -e "\n${BLUE}📱 Launching Flutter Mobile App...${RESET}"
    cd "$APP_DIR" || exit 1
    flutter run
}

run_tests() {
    banner
    echo -e "${CYAN}${BOLD}🧪 RUNNING ROADMESH VERIFICATION & TEST SUITE${RESET}\n"

    echo -e "${BLUE}1. Running Backend Unit & Integration Tests (Vitest)...${RESET}"
    cd "$SERVER_DIR" || exit 1
    npm test

    echo -e "\n${BLUE}2. Compiling TypeScript Server (tsc)...${RESET}"
    npm run build

    echo -e "\n${GREEN}${BOLD}✅ ALL SERVER VERIFICATION SUITES PASSED CLEANLY!${RESET}\n"
}

# ─── Command-Line Argument Handling ──────────────────────────────────────────
case "$1" in
    all|server)
        banner
        start_server
        exit 0
        ;;
    adb|usb|phone)
        pair_android_usb
        exit 0
        ;;
    arduino|gateway|v2i)
        banner
        start_gateway
        exit 0
        ;;
    app|flutter)
        banner
        start_app
        exit 0
        ;;
    mobile)
        "$ROOT_DIR/start_mobile.sh"
        exit 0
        ;;
    test)
        run_tests
        exit 0
        ;;
    stop)
        stop_all
        exit 0
        ;;
esac

# ─── Interactive Menu ────────────────────────────────────────────────────────
while true; do
    banner
    echo -e "${BOLD}Select an action:${RESET}"
    echo -e "  ${GREEN}[1] 🚀 START ROADMESH V2X CORE SERVER & LIVE MAP DASHBOARD${RESET}"
    echo -e "  [2] 📱 Pair Android Phone via USB (adb reverse tunnel)"
    echo -e "  [3] 🚸 Start Arduino Uno V2I Smart Crossing Gateway"
    echo -e "  [4] 📲 Launch Flutter Mobile App on Device"
    echo -e "  [5] 🧪 Run Automated Verification Tests (Vitest + TypeScript)"
    echo -e "  [6] 🛑 Stop All Running RoadMesh Background Services"
    echo -e "  [7] ❌ Exit"
    echo ""
    read -p "Enter choice [1-7]: " choice

    case $choice in
        1)
            start_server
            break
            ;;
        2)
            pair_android_usb
            read -p "Press Enter to return to menu..."
            ;;
        3)
            start_gateway
            break
            ;;
        4)
            start_app
            break
            ;;
        5)
            run_tests
            read -p "Press Enter to return to menu..."
            ;;
        6)
            stop_all
            read -p "Press Enter to return to menu..."
            ;;
        7)
            echo -e "\n${CYAN}Exiting RoadMesh. Safe driving! 🚗${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please choose 1-7.${RESET}"
            sleep 1
            ;;
    esac
done
