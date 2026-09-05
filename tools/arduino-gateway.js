#!/usr/bin/env node

// ─── RoadMesh: Arduino Uno V2I Edge Gateway ─────────────────────────────────
//
// Connects the Arduino Uno Smart Roadside Unit (RSU) to the RoadMesh server via WebSocket.
//
// Features:
//   - Automatically scans and connects to Arduino Uno USB serial port (e.g. /dev/cu.usbmodem*)
//   - Interactive keyboard fallback: Press [SPACE] or [T] in terminal to trigger event instantly
//   - Broadcasts real-time School Crossing V2I telemetry to ws://localhost:3000/ws

const WebSocket = require('ws');
const readline = require('readline');
const fs = require('fs');

const WS_URL = process.env.WS_URL || 'ws://localhost:3000/ws';
const SCHOOL_LAT = 10.0261;
const SCHOOL_LNG = 76.3125;
const RSU_ID = 'rsu-school-01';

console.log(`
╔══════════════════════════════════════════════════════════════╗
║   🚸  RoadMesh: Arduino UNO V2I Smart Crossing Gateway       ║
║   Bridge between Arduino Roadside Pole & RoadMesh Server     ║
║                                                              ║
║   Server: ${WS_URL.padEnd(47)}║
║   Location: Model Public School Zebra Crossing               ║
║   Coordinates: [${SCHOOL_LAT}, ${SCHOOL_LNG}]                           ║
║                                                              ║
║   [SPACE] or [T] = Trigger crossing event manually           ║
║   [Ctrl+C]       = Exit gateway                              ║
╚══════════════════════════════════════════════════════════════╝
`);

let ws = null;
let isConnected = false;
let isCrossingActive = false;
let crossingTimer = null;
let heartbeatInterval = null;

// ─── Connect to RoadMesh WebSocket Server ───────────────────────────────────

function connectWebSocket() {
    console.log(`Connecting to RoadMesh server at ${WS_URL}...`);
    ws = new WebSocket(WS_URL);

    ws.on('open', () => {
        isConnected = true;
        console.log('✅ Connected to RoadMesh Server via WebSocket!');

        // Register RSU as a stationary safety infrastructure beacon
        sendTelemetry(false);

        // Keep-alive heartbeat every 5s
        heartbeatInterval = setInterval(() => {
            if (isConnected && isCrossingActive) {
                sendTelemetry(true);
            }
        }, 1000);
    });

    ws.on('message', (data) => {
        try {
            const msg = JSON.parse(data.toString());
            if (msg.type === 'REGISTER') {
                console.log(`[Server] RSU registered with ID: ${msg.payload.id}`);
            }
        } catch (e) {
            // Ignore parse errors
        }
    });

    ws.on('close', () => {
        isConnected = false;
        clearInterval(heartbeatInterval);
        console.log('⚠️  Disconnected from server. Reconnecting in 3s...');
        setTimeout(connectWebSocket, 3000);
    });

    ws.on('error', (err) => {
        console.error('❌ WebSocket error:', err.message);
    });
}

/**
 * Send RSU telemetry to RoadMesh server.
 */
function sendTelemetry(active) {
    if (!ws || ws.readyState !== WebSocket.OPEN) return;

    const payload = {
        type: 'POSITION_UPDATE',
        timestamp: Date.now(),
        payload: {
            lat: SCHOOL_LAT,
            lng: SCHOOL_LNG,
            speed: active ? 1 : 0,  // Active hazard
            heading: 0,
            vehicleType: 'PEDESTRIAN', // Marks as Vulnerable Road User at crossing
            timestamp: Date.now()
        }
    };

    ws.send(JSON.stringify(payload));
}

/**
 * Handle incoming crossing activation event from Arduino.
 */
function triggerCrossing() {
    if (isCrossingActive) {
        console.log('⏳ Crossing beacon is already ACTIVE. Ignoring duplicate trigger.');
        return;
    }

    isCrossingActive = true;
    console.log('\n🚨 ══════════════════════════════════════════════════════════════');
    console.log('   [ARDUINO EVENT] PEDESTRIAN CROSSING BUTTON PRESSED!');
    console.log('   Broadcasting V2I Safety Zone (Speed Limit: 20 km/h) to all cars...');
    console.log('   Duration: 20 seconds');
    console.log('══════════════════════════════════════════════════════════════\n');

    // Send high-frequency updates to trigger collision warnings for nearby cars
    sendTelemetry(true);

    if (crossingTimer) clearTimeout(crossingTimer);
    crossingTimer = setTimeout(() => {
        isCrossingActive = false;
        console.log('🟢 [ARDUINO EVENT] Crossing period cleared. Beacon back to STANDBY.');
        sendTelemetry(false);
    }, 20000);
}

// ─── Auto-Detect & Read Arduino USB Serial Port ─────────────────────────────

function setupSerialListener() {
    let serialPath = null;

    try {
        const files = fs.readdirSync('/dev');
        // Search for Mac or Linux Arduino serial devices
        const arduinoPort = files.find(f => f.startsWith('cu.usbmodem') || f.startsWith('ttyACM') || f.startsWith('ttyUSB'));
        if (arduinoPort) {
            serialPath = `/dev/${arduinoPort}`;
            console.log(`🔌 Detected Arduino Uno on port: ${serialPath}`);
        }
    } catch (e) {
        // Fall back
    }

    if (serialPath) {
        try {
            const { exec } = require('child_process');
            // Configure baud rate to 115200
            exec(`stty -f ${serialPath} 115200 raw`, (err) => {
                if (!err) {
                    const stream = fs.createReadStream(serialPath, { encoding: 'utf8' });
                    const rl = readline.createInterface({ input: stream });

                    rl.on('line', (line) => {
                        console.log(`[Arduino Serial] ${line}`);
                        if (line.includes('PEDESTRIAN_CROSSING') || line.includes('CROSSING_ALERT')) {
                            triggerCrossing();
                        }
                    });

                    console.log('✅ Serial stream listening to Arduino Uno hardware triggers!');
                }
            });
        } catch (err) {
            console.log('ℹ️  Using keyboard fallback for Arduino simulation.');
        }
    } else {
        console.log('ℹ️  No Arduino Uno hardware detected on USB right now.');
        console.log('👉 Press [SPACE] or [T] to simulate the Arduino button press anytime!\n');
    }
}

// ─── Interactive Keyboard Trigger ───────────────────────────────────────────

readline.emitKeypressEvents(process.stdin);
if (process.stdin.isTTY) {
    process.stdin.setRawMode(true);
}

process.stdin.on('keypress', (str, key) => {
    if (key.ctrl && key.name === 'c') {
        process.exit();
    }

    if (key.name === 'space' || str === 't' || str === 'T') {
        console.log('\n[Keypress] Simulating Arduino Pin 2 Ground Touch...');
        triggerCrossing();
    }
});

// ─── Start ───────────────────────────────────────────────────────────────────

connectWebSocket();
setupSerialListener();
