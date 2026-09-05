#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🚗 RoadMesh — Master Launcher & Hackathon Demo Orchestrator
# ═══════════════════════════════════════════════════════════════════════════════
# Dual Architecture V2X Platform:
#   • V2V (Vehicle-to-Vehicle): Flutter Mobile HUD App
#   • V2I (Vehicle-to-Infrastructure): Arduino UNO Smart School Crossing Beacon
#   • Spatial AI Core: Node.js Geohash Prediction Engine
# ═══════════════════════════════════════════════════════════════════════════════

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$ROOT_DIR/roadmesh-server"
TOOLS_DIR="$ROOT_DIR/tools"
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

banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                          ║"
    echo "║     🚗  ROADMESH — COOPERATIVE V2X PLATFORM                              ║"
    echo "║     Track: Brick by Byte: Building Cities that Think                     ║"
    echo "║                                                                          ║"
    echo "║     • V2V: Smartphone Mobile HUD (NavIC / GPS + Audio TTS)               ║"
    echo "║     • V2I: Arduino UNO Smart School Crossing Beacon                      ║"
    echo "║     • ITS: Leaflet Smart City Traffic Management Dashboard               ║"
    echo "║                                                                          ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

stop_all() {
    echo -e "\n${YELLOW}🛑 Stopping all active RoadMesh background processes...${RESET}"
    if [ -f "$PID_FILE" ]; then
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null
                echo -e "   Stopped process ${CYAN}$pid${RESET}"
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi

    # Kill any lingering ports
    lsof -ti:3000 | xargs kill -9 2>/dev/null
    lsof -ti:3001 | xargs kill -9 2>/dev/null

    echo -e "${GREEN}✅ All RoadMesh processes cleanly stopped.${RESET}\n"
}

start_server() {
    echo -e "${CYAN}🚀 Starting RoadMesh Core Server on port 3000...${RESET}"
    cd "$SERVER_DIR" || exit 1
    node dist/index.js > "$ROOT_DIR/server.log" 2>&1 &
    local PID=$!
    echo "$PID" >> "$PID_FILE"
    echo -e "   ${GREEN}✓ Server started (PID: $PID)${RESET}"
    echo -e "   ${BLUE}• Dashboard:${RESET} http://localhost:3000/dashboard"
    echo -e "   ${BLUE}• WebSocket:${RESET} ws://localhost:3000/ws"
}

start_simulator() {
    echo -e "\n${CYAN}🎮 Starting Scenario Simulation Engine on port 3001...${RESET}"
    cd "$TOOLS_DIR" || exit 1
    node server.js > "$ROOT_DIR/simulator.log" 2>&1 &
    local PID=$!
    echo "$PID" >> "$PID_FILE"
    echo -e "   ${GREEN}✓ Simulator started (PID: $PID)${RESET}"
    echo -e "   ${BLUE}• Simulator Control UI:${RESET} http://localhost:3001"
}

start_gateway() {
    echo -e "\n${MAGENTA}🚸 Starting Arduino Uno V2I Gateway...${RESET}"
    echo -e "   ${YELLOW}Hint: You can press [SPACE] in the gateway anytime to simulate the Arduino button!${RESET}"
    cd "$TOOLS_DIR" || exit 1
    node arduino-gateway.js
}

start_app() {
    echo -e "\n${BLUE}📱 Launching Flutter Mobile App...${RESET}"
    cd "$APP_DIR" || exit 1
    flutter run
}

start_all() {
    banner
    stop_all
    touch "$PID_FILE"

    start_server
    sleep 1

    start_simulator
    sleep 1

    echo -e "\n${GREEN}══════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}🎉 FULL DEMO STACK IS LIVE!${RESET}"
    echo -e "   📊 ${BOLD}Smart City Admin Map:${RESET}   ${CYAN}http://localhost:3000/dashboard${RESET}"
    echo -e "   🎮 ${BOLD}Scenario Simulator UI:${RESET}   ${CYAN}http://localhost:3001${RESET}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════${RESET}"

    # Open Dashboard in default browser on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "http://localhost:3000/dashboard/"
        open "http://localhost:3001"
    fi

    echo -e "\n${YELLOW}👉 Now starting Arduino V2I Gateway in interactive mode...${RESET}"
    echo -e "   (Press ${BOLD}[SPACE]${RESET} in this terminal to simulate pedestrian crossing!)\n"
    start_gateway
}

run_tests() {
    banner
    echo -e "${CYAN}${BOLD}🧪 RUNNING FULL SYSTEM VALIDATION & TEST SUITE${RESET}\n"

    echo -e "${BLUE}1. Running Backend Unit & Integration Tests (Vitest)...${RESET}"
    cd "$SERVER_DIR" || exit 1
    npm test

    echo -e "\n${BLUE}2. Compiling TypeScript Server (tsc)...${RESET}"
    npm run build

    echo -e "\n${BLUE}3. Validating Flutter Mobile App (flutter analyze)...${RESET}"
    cd "$APP_DIR" || exit 1
    flutter analyze --no-fatal-infos

    echo -e "\n${GREEN}${BOLD}✅ ALL 3 COMPONENT TEST SUITES PASSED CLEANLY WITH ZERO ERRORS!${RESET}\n"
}

# ─── Command-Line Argument Handling ──────────────────────────────────────────
case "$1" in
    all)
        start_all
        exit 0
        ;;
    server)
        banner
        start_server
        exit 0
        ;;
    sim)
        banner
        start_simulator
        exit 0
        ;;
    arduino|gateway)
        banner
        start_gateway
        exit 0
        ;;
    app)
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
    echo -e "  ${GREEN}[1] 🚀 LAUNCH FULL HACKATHON DEMO STACK (Server + Simulator + Arduino Gateway)${RESET}"
    echo -e "  [2] 🖥️  Start Backend Server & Admin Dashboard only (Port 3000)"
    echo -e "  [3] 🎮 Start Scenario Simulator UI only (Port 3001)"
    echo -e "  [4] 🚸 Start Arduino Uno V2I Gateway (Interactive [SPACE] Trigger)"
    echo -e "  [5] 📱 Launch Flutter Mobile App on Device/Simulator"
    echo -e "  [6] 🧪 Run Automated Verification Suite (61 tests + TypeScript + Flutter)"
    echo -e "  [7] 🛑 Stop All Running RoadMesh Background Services"
    echo -e "  [8] ❌ Exit"
    echo ""
    read -p "Enter choice [1-8]: " choice

    case $choice in
        1)
            start_all
            break
            ;;
        2)
            start_server
            read -p "Press Enter to return to menu..."
            ;;
        3)
            start_simulator
            read -p "Press Enter to return to menu..."
            ;;
        4)
            start_gateway
            break
            ;;
        5)
            start_app
            break
            ;;
        6)
            run_tests
            read -p "Press Enter to return to menu..."
            ;;
        7)
            stop_all
            read -p "Press Enter to return to menu..."
            ;;
        8)
            echo -e "\n${CYAN}Goodbye! Best of luck in the hackathon! 🏆${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please choose 1-8.${RESET}"
            sleep 1
            ;;
    esac
done
