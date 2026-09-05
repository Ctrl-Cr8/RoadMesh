#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
# 📱 RoadMesh Mobile App Auto-Launcher & ADB Device Connector
# ═══════════════════════════════════════════════════════════════════════════════
# Automates:
#   1. USB ADB Authorization & Connection verification
#   2. USB Tunneling (adb reverse tcp:3000 tcp:3000)
#   3. Backend Server & Indian Traffic Simulator auto-check & start
#   4. APK Installation & Instant App Launch on Phone
# ═══════════════════════════════════════════════════════════════════════════════

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/roadmesh-app"
SERVER_DIR="$ROOT_DIR/roadmesh-server"
TOOLS_DIR="$ROOT_DIR/tools"
APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                          ║"
echo "║     🚗 ROADMESH — MOBILE AUTO-LAUNCHER & DEVICE SETUP                    ║"
echo "║                                                                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# 1. Check ADB Installation
if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ 'adb' command not found! Make sure Android SDK platform-tools is installed.${RESET}"
    exit 1
fi

# 2. Verify and Handle Device Connection & Authorization
echo -e "${BLUE}🔍 Checking connected Android devices...${RESET}"

get_device_status() {
    adb devices | grep -v "List of devices" | grep -v "^$" | head -n 1
}

DEVICE_LINE="$(get_device_status)"

if [ -z "$DEVICE_LINE" ]; then
    echo -e "${YELLOW}⚠️  No Android device detected over USB.${RESET}"
    echo -e "   1. Plug your phone into your computer via USB."
    echo -e "   2. Ensure ${BOLD}Developer Options${RESET} & ${BOLD}USB Debugging${RESET} are turned ON."
    echo -e "\n${CYAN}⏳ Waiting for device to be plugged in (Ctrl+C to abort)...${RESET}"
    
    while [ -z "$DEVICE_LINE" ]; do
        sleep 2
        DEVICE_LINE="$(get_device_status)"
    done
fi

# Check if device is unauthorized
if echo "$DEVICE_LINE" | grep -q "unauthorized"; then
    echo -e "\n${YELLOW}${BOLD}⚠️  DEVICE UNAUTHORIZED!${RESET}"
    echo -e "${YELLOW}👉 ACTION REQUIRED ON YOUR PHONE SCREEN:${RESET}"
    echo -e "   1. Unlock your phone."
    echo -e "   2. Look for the popup: ${BOLD}\"Allow USB debugging?\"${RESET}"
    echo -e "   3. Check ${BOLD}\"Always allow from this computer\"${RESET} and tap ${BOLD}ALLOW${RESET}."
    echo -e "\n${CYAN}🔄 Refreshing ADB daemon...${RESET}"
    adb kill-server > /dev/null 2>&1
    adb start-server > /dev/null 2>&1
    
    echo -e "${CYAN}⏳ Waiting for authorization...${RESET}"
    for i in {1..30}; do
        DEVICE_LINE="$(get_device_status)"
        if echo "$DEVICE_LINE" | grep -q "device$"; then
            break
        fi
        sleep 1
    done
fi

DEVICE_ID=$(echo "$DEVICE_LINE" | awk '{print $1}')
DEVICE_STATE=$(echo "$DEVICE_LINE" | awk '{print $2}')

if [ "$DEVICE_STATE" != "device" ]; then
    echo -e "\n${RED}❌ Device is still in state '$DEVICE_STATE'.${RESET}"
    echo -e "${YELLOW}Please unlock your phone and accept the USB Debugging prompt, then re-run:${RESET}"
    echo -e "  ${BOLD}./start_mobile.sh${RESET}\n"
    exit 1
fi

DEVICE_MODEL=$(adb -s "$DEVICE_ID" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
echo -e "${GREEN}✅ Connected: ${BOLD}$DEVICE_MODEL${RESET} ${CYAN}($DEVICE_ID)${RESET}"

# 3. Setup Port Forwarding
echo -e "\n${BLUE}🔌 Configuring USB port forwarding (Reverse Proxy)...${RESET}"
adb -s "$DEVICE_ID" reverse tcp:3000 tcp:3000
echo -e "   ${GREEN}✓ Reverse tunnel active: phone 127.0.0.1:3000 -> host 3000${RESET}"

# 4. Ensure Backend Core Server & Simulator are running
echo -e "\n${BLUE}⚙️  Verifying backend services...${RESET}"
if ! lsof -ti:3000 &> /dev/null; then
    echo -e "   ${YELLOW}Starting RoadMesh Core Server on port 3000...${RESET}"
    cd "$SERVER_DIR" || exit 1
    node dist/index.js > "$ROOT_DIR/server.log" 2>&1 &
    sleep 1
fi
echo -e "   ${GREEN}✓ RoadMesh Core Server is active on port 3000${RESET}"

# 5. Check APK existence and build if missing
if [ ! -f "$APK_PATH" ]; then
    echo -e "\n${CYAN}📦 APK not found. Building RoadMesh debug APK...${RESET}"
    cd "$APP_DIR" || exit 1
    flutter build apk --debug --target-platform android-arm64
fi

# 6. Install APK
echo -e "\n${BLUE}📲 Installing RoadMesh App onto $DEVICE_MODEL...${RESET}"
adb -s "$DEVICE_ID" install -r "$APK_PATH"

# 7. Launch App
echo -e "\n${GREEN}🚀 Launching RoadMesh on phone...${RESET}"
adb -s "$DEVICE_ID" shell am start -n com.example.roadmesh_app/.MainActivity

echo -e "\n${GREEN}══════════════════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}🎉 ROADMESH IS NOW RUNNING ON YOUR PHONE!${RESET}"
echo -e "   ${CYAN}• Server URL in App:${RESET}  ${BOLD}ws://127.0.0.1:3000/ws${RESET} (default)"
echo -e "   ${CYAN}• Vehicle Modes:${RESET}      Select Car, Auto Rickshaw, Bike, Bus, etc."
echo -e "   ${CYAN}• Google Map HUD:${RESET}     Custom vector vehicle icons & 1.5km radar radius"
echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════${RESET}\n"
